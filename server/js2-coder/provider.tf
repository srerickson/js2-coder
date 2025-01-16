terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.0.0"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.13.0"
    }
  }
}