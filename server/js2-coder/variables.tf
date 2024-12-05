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

variable "js2_allocation" {
    description = "your jetstream2 allocation ID (e.g., bio123456)"
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


variable "acme_email" {
    description = "email address used for ACME certificates"
    type = string
}

variable "os_auth_url" {
    description = "Jetstream2/OpenStack Authentication URL"
    type = string
    default = "https://js2.jetstream-cloud.org:5000/v3/"
}

variable "os_region_name" {
    description = "Jetstream2/OpenStack Region"
    type = string
    default = "IU"
}

variable "os_application_credential_id" {
    description = "Jetstream2/OpenStack Credential ID"
    type = string
    sensitive = true
}

variable "os_application_credential_secret" {
    description = "Jetstream2/OpenStack Credential Secret"
    type = string
    sensitive = true
}

variable "tags" {
  description = "Tags to set on all resources."
  type        = list(string)
  default     = []
}