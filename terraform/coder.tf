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
  security_groups = ["default", openstack_networking_secgroup_v2.dcn_coder.name]
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

resource "openstack_networking_secgroup_v2" "dcn_coder" {
  name = "terraform_ssh_https_icmp"
  description = "Security group with SSH, HTTP/S, and PING open to 0.0.0.0/0"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.dcn_coder.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.dcn_coder.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.dcn_coder.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.dcn_coder.id
}
