#################
# Storage Config
#################


resource "openstack_sharedfilesystem_share_v2" "dcn_share" {
  name             = "dcn_data"
  description      = "DCN Submissions"
  share_proto      = "CEPHFS"
  size             = 500 // 500 GiB
}

resource "openstack_sharedfilesystem_share_access_v2" "dcn_share_access_rw" {
  share_id     = openstack_sharedfilesystem_share_v2.dcn_share.id
  access_type  = "cephx"
  access_to    = "dcn_dataRW" # for cephx this is a descriptive name
  access_level = "rw"
}

resource "openstack_sharedfilesystem_share_access_v2" "dcn_share_access_ro" {
  share_id     = openstack_sharedfilesystem_share_v2.dcn_share.id
  access_type  = "cephx"
  access_to    = "dcn_dataRO" # for cephx this is a descriptive name
  access_level = "ro"
}

resource "openstack_objectstorage_container_v1" "dcn_container" {
  name   = "DCN Container"
  metadata = {
    test = "true"
    terraform = "true"
  }
}