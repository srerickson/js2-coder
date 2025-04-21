terraform {
  required_providers {
    coderd = {
      source = "coder/coderd"
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "dreamlab-tf"
    key            = "dcn-js2/workspaces.tfstate"
    region         = "us-west-2"
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

variable "s3_access_key_id" {
  type = string
  sensitive = true
}

variable "s3_secret_access_key" {
  type = string
  sensitive = true
}

locals {
  workspace_network = "auto_allocated_network"
  featured_image    = "Featured-Ubuntu24"
}

resource "coderd_template" "default" {
  name         = "default"
  display_name = "Ubuntu VM"
  description  = "Using the most recent featured Ubuntu image maintained by the JetStream2 team (${local.featured_image})"
  icon         = "/icon/ubuntu.svg"
  versions     = [
    {
      directory = "./default"
      active    = true
      tf_vars = [
        {
          name = "boot_image"
          value = local.featured_image
        }, {
          name = "workspace_network"
          value = local.workspace_network
        },
        {
          name = "s3_access_key_id",
          value = var.s3_access_key_id
        },
        {
          name = "s3_secret_access_key"
          value = var.s3_secret_access_key
        }
      ]
    }
  ]
  
}