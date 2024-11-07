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

locals {
  network_name = "dcn_network"
  coder_server_hostname = "coder-server"
}


data "coder_parameter" "instance_type" {
  name         = "instance_type"
  display_name = "Instance Type"
  description  = "What size instance for your workspace?"
  default      = 3
  option {
    name  = "small (2 CPUs, 6GB memory)"
    value = 2
  }
  option {
    name  = "medium (4 CPUs, 15GB memory)"
    value = 3
  }
  option {
    name  = "large (8 CPUs, 30GB memory)"
    value = 4
  }
}

data "coder_parameter" "instance_image" {
  name         = "instance_image"
  display_name = "Operating System"
  description  = "Choose an operating system for the instance."
  default      = "b9d0deb4-4fc5-447d-a11b-24652feb5ef7"
  mutable      = false
  option {
    name  = "Ubuntu 24.04 LTS"
    value = "b9d0deb4-4fc5-447d-a11b-24652feb5ef7"
  } 
}


data "openstack_networking_network_v2" "terraform" {
  name = local.network_name
}

locals {
  linux_user = "coder"
  user_data  = <<-EOT
  Content-Type: multipart/mixed; boundary="//"
  MIME-Version: 1.0

  --//
  Content-Type: text/cloud-config; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="cloud-config.txt"

  #cloud-config
  cloud_final_modules:
  - [scripts-user, always]
  hostname: ${lower(data.coder_workspace.env.name)}
  users:
  - name: ${local.linux_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

  --//
  Content-Type: text/x-shellscript; charset="us-ascii"
  MIME-Version: 1.0
  Content-Transfer-Encoding: 7bit
  Content-Disposition: attachment; filename="userdata.txt"

  #!/bin/bash
  
  # packages we need
  apt-get update
  apt-get install -y jq

  # Jetstream2 Networking issue:
  # instances *without* public/floating IPs can't reach instances 
  # *with* public/floating IPs using the latter's public/floating IP.
  # See https://docs.jetstream-cloud.org/faq/trouble/#i-cant-ping-or-reach-a-publicfloating-ip-from-an-internal-non-routed-host
  # To address this, we need to create an entry in /etc/hosts for
  # for the Coder server's access url that uses the private IP adress.

  # trim https:// from the access url value
  coder_host=$(echo "${lower(data.coder_workspace.env.access_url)}" | sed 's/.*\/\///')
  
  # ip address for coder server
  coder_ipv4=$(getent hosts ${local.coder_server_hostname} | awk '{ print $1 }')

  # add coder_host to /etc/hosts
  if [ -n "$coder_host" ] && [ -n "$coder_ipv4" ]; then
    grep -v "$coder_host" /etc/hosts > /etc/hosts.tmp
    echo "$coder_ipv4 $coder_host" >> /etc/hosts.tmp
    mv /etc/hosts.tmp /etc/hosts
  fi

  # Install Docker
  if ! command -v docker &> /dev/null
  then
    echo "Docker not found, installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh 2>&1 >/dev/null
    usermod -aG docker ${local.linux_user}
    newgrp docker
  else
    echo "Docker is already installed."
  fi
  
  # Install ocfl tools
  if ! command -v ocfl &> /dev/null
  then
    ocfl_tools=https://github.com/srerickson/ocfl-tools/releases/download/v0.1.1/ocfl-tools_Linux_x86_64.tar.gz
    curl -fsSL "$ocfl_tools" -o ocfl.tar.gz && tar -C /usr/local/bin -xzf ocfl.tar.gz && rm ocfl.tar.gz
  fi

  # Grabs token via the internal metadata server. This IP address is the same for all instances, no need to change it
  # https://docs.openstack.org/nova/rocky/user/metadata-service.html
  export CODER_AGENT_TOKEN=$(curl -s http://169.254.169.254/openstack/latest/meta_data.json | jq -r .meta.coder_agent_token)

  # Run coder agent
  sudo --preserve-env=CODER_AGENT_TOKEN -u ${local.linux_user} sh -c 'export  && ${try(coder_agent.dev[0].init_script, "")}'
  --//--
  EOT
}

data "coder_workspace" "env" {}
data "coder_workspace_owner" "me" {}

resource "openstack_identity_ec2_credential_v3" "ec2_key1" {}

resource "coder_agent" "dev" {
  count          = data.coder_workspace.env.start_count
  arch           = "amd64"
  auth           = "token"
  os             = "linux"
  startup_script = <<-EOT
    set -e
    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT

  env = {
    AWS_ENDPOINT_URL = "https://js2.jetstream-cloud.org:8001"
    AWS_SECRET_ACCESS_KEY = "${openstack_identity_ec2_credential_v3.ec2_key1.secret}"
    AWS_ACCESS_KEY_ID = "${openstack_identity_ec2_credential_v3.ec2_key1.access}"
    AWS_REGION = "IU" # not really used (aws client needs it to be set)
    OCFL_ROOT = "s3://dcn_data/shared"
    OCFL_USER_NAME = "${data.coder_workspace_owner.me.full_name}"
    OCFL_USER_EMAIL = "${data.coder_workspace_owner.me.email}"
    OCFL_S3_PATHSTYLE = "true"
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

resource "coder_app" "code-server" {
  count        = data.coder_workspace.env.start_count
  agent_id     = coder_agent.dev[0].id
  slug         = "code-server"
  display_name = "code-server"
  url          = "http://localhost:13337/?folder=/home/coder"
  icon         = "/icon/code.svg"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}


# creating Ubuntu22 instance
resource "openstack_compute_instance_v2" "vm" {
  name ="coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.env.name}"
  flavor_id = data.coder_parameter.instance_type.value
  key_pair = "dcn_coder_keypair" // FIXME
  security_groups   = ["default"]
  metadata = {
    coder_agent_token = try(coder_agent.dev[0].token, "")
  }
  user_data = local.user_data
  block_device {
    uuid                  = data.coder_parameter.instance_image.value
    source_type           = "image"
    volume_size           = 80
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  network {
    name = data.openstack_networking_network_v2.terraform.name
  }
  lifecycle {
    ignore_changes = [ user_data ]
  }
  power_state = data.coder_workspace.env.transition == "start" ? "active" : "shelved_offloaded"
  tags = ["Name=coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.env.name}", "Coder_Provisioned=true"]  
}