#################
# Storage Config
#################


resource "openstack_objectstorage_container_v1" "dcn_container" {
  name   = var.data_container
  metadata = {
    test = "true"
    terraform = "true"
  }
}