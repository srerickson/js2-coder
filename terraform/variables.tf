variable "js2_project" {
    type = string
    default = "oth240004"
}

variable "data_container" {
    type = string
    default = "dcn_data"
}

variable "fcos_image_url" {
    type = string
    default = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20241109.3.0/x86_64/fedora-coreos-41.20241109.3.0-openstack.x86_64.qcow2.xz"
}

variable "tags" {
    type = list(string)
    default = ["opentofu"]
}
