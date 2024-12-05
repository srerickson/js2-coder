

resource "openstack_images_image_v2" "fcos" {
  name             = "FedoraCoreOS"
  image_source_url = var.fcos_image_url
  container_format = "bare"
  disk_format      = "qcow2"
  decompress       = true
}


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


