terraform {
  required_providers {
    coder = {
      source = "coder/coder"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 2.0.0"
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
    name  = "m3.tiny (1 CPU, 3GB ram, 20GB disk)"
    value = 1
  }
  option {
    name  = "m3.small (2 CPUs, 6GB ram, 20GB disk"
    value = 2
  }
  option {
    name  = "m3.quad (4 CPUs, 15GB ram, 20GB disk)"
    value = 3
  }
  option {
    name  = "m3.medium (8 CPUs, 30GB ram, 60GB disk)"
    value = 4
  }
  option {
    name  = "m3.large (16 CPUs, 60GB ram, 60GB disk)"
    value = 5
  }
}

data "coder_parameter" "instance_image" {
  name         = "instance_image"
  display_name = "Operating System"
  description  = "Choose an operating system for the instance."
  default      = "2b7cfcd8-04a7-4b1b-99ea-6a1e34e543e4"
  mutable      = false
  option {
    name  = "Ubuntu 24 (Featured, Minimal)"
    value = "2b7cfcd8-04a7-4b1b-99ea-6a1e34e543e4"
  }
   option {
    name  = "Ubuntu 24 (Preview)"
    value = "d9fd3307-6bf2-4da4-8e1b-2a5404c3b61a"
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
    AWS_ACCESS_ID = "${openstack_identity_ec2_credential_v3.ec2_key1.access}"
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
  image_id  = data.coder_parameter.instance_image.value
  flavor_id = data.coder_parameter.instance_type.value
  key_pair = "dcn_coder_keypair" // FIXME
  security_groups   = ["default"]
  metadata = {
    coder_agent_token = try(coder_agent.dev[0].token, "")
  }
  user_data = local.user_data
  network {
    name = data.openstack_networking_network_v2.terraform.name
  }
  lifecycle {
    ignore_changes = [ user_data ]
  }
  power_state = data.coder_workspace.env.transition == "start" ? "active" : "shelved_offloaded"
  tags = ["Name=coder-${data.coder_workspace_owner.me.name}-${data.coder_workspace.env.name}", "Coder_Provisioned=true"]  
}