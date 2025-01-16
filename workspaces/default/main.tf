terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0.0"
    }
  }
}

provider "openstack" {}

variable "workspace_network" {
  description = "name of network the vm will join"
  type = string
}

variable "boot_image" {
  description = "name of the disk image to boot workspace vms"
  type = string
}

variable "flavor_name" {
  description = "instance size"
  type = string
  default = "m3.quad"
}

# data "coder_parameter" "instance_type" {
#   name         = "instance_type"
#   display_name = "Instance Type"
#   description  = "What size instance for your workspace?"
#   default      = "m3.small"
#   option {
#     name  = "m3.small (2 CPUs, 6GB mem)"
#     value = "m3.small"
#   }
#   option {
#     name  = "m3.quad (4 CPUs, 15GB mem)"
#     value = "m3.quad"
#   }
#   option {
#     name  = "m3.medium (8 CPUs, 30GB mem)"
#     value = "m3.medium"
#   }
#   option {
#     name  = "m3.large (16 CPUs, 60GB mem)"
#     value = "m3.large"
#   }
#   option {
#     name  = "m3.xl (32 CPUs, 125GB mem)"
#     value = "m3.xl"
#   }
#   option {
#     name  = "g3.medium (8 CPUs, 30GB mem, GPU)"
#     value = "g3.medium"
#   }
#   option {
#     name  = "g3.large (16 CPUs, 60GB mem, GPU)"
#     value = "g3.large"
#   }
#   option {
#     name  = "g3.xl (32 CPUs, 125GB mem, GPU)"
#     value = "g3.xl"
#   }
# }

locals {
  linux_user = "coder"
  hostname = lower(data.coder_workspace.env.name)
}

data "coder_workspace" "env" {}
data "coder_workspace_owner" "me" {}

resource "coder_agent" "dev" {
  count          = data.coder_workspace.env.start_count
  arch           = "amd64"
  auth           = "token"
  os             = "linux"
  startup_script = <<-EOT
    set -e
    # start rstudio 
    docker run --rm -d --name rstudio \
      -p 127.0.0.1:8787:8787 \
      -v $(echo $GIT_SSH_COMMAND | cut -d" " -f1):/tmp/coder/coder \
      -v /home/coder:/home/rstudio \
      -e ROOT=true \
      -e DISABLE_AUTH=true \
      -e USERID=$(id -u) \
      -e GROUPID=$(id -g) \
      -e GIT_SSH_COMMAND='/tmp/coder/coder gitssh --' \
      -e CODER \
      -e CODER_AGENT_URL \
      -e CODER_AGENT_AUTH \
      -e CODER_AGENT_TOKEN \
      -e CODER_AGENT_URL \
      -e CODER_WORKSPACE_AGENT_NAME \
      -e CODER_WORKSPACE_NAME \
      rocker/tidyverse:latest
  EOT

  display_apps {
    vscode          = false
    vscode_insiders = false
    web_terminal    = false
    ssh_helper      = false
  }

  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat cpu"
  }
  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = "coder stat mem"
  }
  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = "coder stat disk --path $HOME"
  }
  
}

resource "coder_app" "rstudio" {
  count        = data.coder_workspace.env.start_count
  agent_id     = coder_agent.dev[0].id
  slug         = "rstudio"
  display_name = "RStudio"
  url          = "http://localhost:8787"
  icon         = "/icon/rstudio.svg"
  subdomain    = true
  share        = "owner"
  healthcheck {
    url       = "http://localhost:8787/health-check"
    interval  = 5
    threshold = 20
  }
}

module "filebrowser" {
  count    = data.coder_workspace.env.start_count
  source   = "registry.coder.com/modules/filebrowser/coder"
  version  = "1.0.23"
  agent_id = coder_agent.dev[0].id
  database_path = ".config/filebrowser.db"
}

module "vscode-web" {
  count = data.coder_workspace.env.start_count
  source = "registry.coder.com/modules/vscode-web/coder"
  version = "1.0.22"
  agent_id = coder_agent.dev[0].id
  accept_license = true
  folder = "/home/coder"
}

data "cloudinit_config" "user_data" {
  gzip          = false
  base64_encode = false
  boundary = "//"
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/cloud-init/cloud-config.yaml.tftpl", {
      hostname   = local.hostname
      linux_user = local.linux_user
    })
  }
  part {
    filename     = "userdata.sh"
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/cloud-init/userdata.sh.tftpl", {
      linux_user = local.linux_user
      init_script = try(coder_agent.dev[0].init_script, "")
    })
  }
}

resource "openstack_compute_instance_v2" "vm" {
  name ="coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.env.name}"
  image_name  = var.boot_image
  flavor_name = var.flavor_name
  security_groups   = ["default"]
  metadata = {
    coder_agent_token = try(coder_agent.dev[0].token, "")
  }
  user_data = data.cloudinit_config.user_data.rendered
  network {
    name = var.workspace_network
  }
  lifecycle {
    ignore_changes = [ user_data ]
  }
  # shelved_offloaded is the preferred "stopped" state, but we can't change to that state and also update metdata...
  # See this issue: 
  power_state = data.coder_workspace.env.transition == "start" ? "active" : "shutoff"
  tags = ["Name=coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.env.name}", "Coder_Provisioned=true"]  
}

