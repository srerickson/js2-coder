
provider "openstack" {
  #if using cloud.yaml file for authentication:
  #cloud = "OTH240004_IU"
}

variable "email" {
    type = string
    default = "serickson@ucsb.edu"
}

variable "js2_allocation" {
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