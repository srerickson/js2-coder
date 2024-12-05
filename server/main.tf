terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0.0"
    }
  }
}

provider "openstack" {}

variable "email" {
    type = string
    default = "serickson@ucsb.edu"
}

variable "js2_project" {
    type = string
    default = "oth240004"
}

variable "ssh_public_key" {
    type = string
    default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDBH7kcq6B27oiM9KG/ZEVibCC8sK4wIkw732f+q1JXa serickson-local@drm04-l1az"
}

variable "fcos_image_url" {
    type = string
    default = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20241109.3.0/x86_64/fedora-coreos-41.20241109.3.0-openstack.x86_64.qcow2.xz"
}

variable "tags" {
    type = list(string)
    default = ["tofu", "dev"]
}


# getting public network id for routing
data "openstack_networking_network_v2" "public" {
  name = "public"
}

#create a virtual network for this project
resource "openstack_networking_network_v2" "net" {
  name = "mytest-net"
  admin_state_up  = "true"
  tags = var.tags
}

#creating the virtual subnet
resource "openstack_networking_subnet_v2" "subnet" {
  name = "mytest-subnet"
  network_id  = openstack_networking_network_v2.net.id
  cidr  = "192.168.120.0/24"
  ip_version  = 4
}

# router for accessing the public network
resource "openstack_networking_router_v2" "router" {
  name = "mytest-router"
  admin_state_up  = true
  external_network_id = data.openstack_networking_network_v2.public.id
  tags = var.tags
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

# upload fedora coreos disk image for vm boot disk
resource "openstack_images_image_v2" "fcos" {
  name             = "FedoraCoreOS"
  image_source_url = var.fcos_image_url
  container_format = "bare"
  disk_format      = "qcow2"
  decompress       = true
}

# create new credentials, used by coder for launching workspace VMs and
# DNS-based certificates
resource "openstack_identity_application_credential_v3" "coder" {
  name = "coder"
}

module "js2-coder1" {
  source = "./js2-coder"
  
  # settings
  js2_project   = var.js2_project
  hostname      = "coder"
  public_key    = var.ssh_public_key
  fcos_image_id = openstack_images_image_v2.fcos.id
  network_name  = openstack_networking_network_v2.net.name
  acme_email    = var.email
  
  os_application_credential_secret = openstack_identity_application_credential_v3.coder.secret
  os_application_credential_id     = openstack_identity_application_credential_v3.coder.id
  tags = var.tags
}

output "coder_url" {
  value = module.js2-coder1.url
}
