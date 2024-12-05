terraform {
  required_providers {
    coderd = {
      source = "coder/coderd"
    }
  }
}

provider "coderd" {
  url   = var.coder_url
  token = var.coder_token
}

variable "coder_url" {
    type = string
    default = "https://coder.oth240004.projects.jetstream-cloud.org"
}

variable "coder_token" {
    type = string
    sensitive = true
}

variable "workspace_network" {
  description = "network that workspace vms should join"
  type = string
  default = "auto_allocated_network"
}

variable "featured_image" {
  description = "name of default featured image"
  type = string
  default = "Featured-Ubuntu24"
}

resource "coderd_template" "default" {
  name         = "default"
  display_name = "Ubuntu VM"
  description  = "Using the most recent featured Ubuntu image maintained by the JetStream2 team (${var.featured_image})"
  icon         = "/icon/ubuntu.svg"
  versions     = [
    {
      directory = "./default"
      active    = true
      tf_vars = [
        {
          name = "featured_image"
          value = var.featured_image
        }, {
          name = "workspace_network"
          value = var.workspace_network
        }
      ]
    }
  ]
  
}