##################################
# Machine + DNS for running Coder 
##################################

resource "openstack_networking_floatingip_v2" "dcn_coder" {
  pool = "public"
}

resource "openstack_compute_keypair_v2" "dcn_coder" {
  name = "dcn_coder_keypair"
  public_key = file("${path.module}/../keys/coder.pub")
}

resource "openstack_compute_instance_v2" "dcn_coder" {
  name            = "coder-server"
  # Featured-RockyLinux9 
  image_id        = "db525878-8a4d-455d-bbd2-3542e2eff676"
  flavor_id       = "2"
  key_pair        = resource.openstack_compute_keypair_v2.dcn_coder.name
  security_groups = ["default"]
  network {
    name = resource.openstack_networking_network_v2.dcn_network.name
  }
}

data "openstack_networking_port_v2" "dcn_coder" {
  fixed_ip = openstack_compute_instance_v2.dcn_coder.access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "dcn_coder" {
  floating_ip = openstack_networking_floatingip_v2.dcn_coder.address
  port_id = data.openstack_networking_port_v2.dcn_coder.id
}