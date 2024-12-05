variable "namespace" {
    description = "prefix used for named resources created by the module"
    type = string
    default = "coder"
}

variable "hostname" {
    description = "server hostname"
    type = string
    default = "coder"
}

variable "network_name" {
    description = "openstack network vm is part of"
    type = string
}

variable "js2_project" {
    description = "your assigned js2 project id"
    type = string
}

variable "public_key" {
    description = "ssh public key for connecting to coder server vm"
    type = string
}

variable "vm_flavor_name" {
    type = string
    default = "m3.small"
}

variable "fcos_image_id" {
    description = "image id for a recent Fedor CoreOS disk image"
    type = string
}

variable "tags" {
  description = "Tags to set on all resources."
  type        = list(string)
  default     = []
}