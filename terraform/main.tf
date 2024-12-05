

resource "openstack_images_image_v2" "fcos" {
  name             = "FedoraCoreOS"
  image_source_url = var.fcos_image_url
  container_format = "bare"
  disk_format      = "qcow2"
  decompress= true
  properties = {
    key = "value"
  }
}


resource "openstack_objectstorage_container_v1" "dcn_container" {
  name   = var.data_container
  metadata = {
    test = "true"
    terraform = "true"
  }
}


# resource "openstack_identity_application_credential_v3" "coder" {
#   name        = "coder"
# }

module "js2-coder1" {
  source = "./js2-coder"
  js2_project = var.js2_project
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDBH7kcq6B27oiM9KG/ZEVibCC8sK4wIkw732f+q1JXa serickson-local@drm04-l1az"
  fcos_image_id = openstack_images_image_v2.fcos.id
  network_name = openstack_networking_network_v2.net.name
  tags = ["terraform"]
}


