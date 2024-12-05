terraform {
  required_providers {
    coderd = {
      source = "coder/coderd"
    }
  }
}

variable "coder_url" {
    type = string
    default = "https://coder.oth240004.projects.jetstream-cloud.org"
}

variable "coder_token" {
    type = string
    sensitive = true
}

provider "coderd" {
  url   = var.coder_url
  token = var.coder_token
}

resource "coderd_template" "default" {
  name         = "default"
  display_name = "Ubuntu VM"
  description  = "Virtual machine running featured Ubuntu image from JetStream2."
  icon         = "/icon/ubuntu.svg"
  versions     = [{directory   = "./default"}]
}