resource "openstack_compute_instance_v2" "coder" {
  name            = "${var.namespace}-${var.hostname}"
  image_id        = var.fcos_image_id
  flavor_name     = var.vm_flavor_name
  key_pair        = resource.openstack_compute_keypair_v2.coder.name
  user_data       = data.ct_config.coder.rendered
  security_groups = ["default", openstack_networking_secgroup_v2.coder.name]
  network {
    name = var.network_name
  }
  tags = var.tags
}

data "ct_config" "coder" {
  content = file("${path.module}/butane/main.yaml")
  strict = true
  snippets = [
    templatefile("${path.module}/butane/traefik.yaml", {
      acme_email = var.acme_email
      os_region_name = var.os_region_name
      os_auth_url = var.os_auth_url
      os_application_credential_id = var.os_application_credential_id
      os_application_credential_secret = var.os_application_credential_secret
    }),
    templatefile("${path.module}/butane/coder.yaml", {
      hostname = var.hostname
      js2_project = var.js2_project
      os_region_name = var.os_region_name
      os_auth_url = var.os_auth_url
      os_application_credential_id = var.os_application_credential_id
      os_application_credential_secret = var.os_application_credential_secret
    }),
  ]
}

# associate vm with public ip
resource "openstack_networking_floatingip_v2" "coder" {
  pool = "public"
}

data "openstack_networking_port_v2" "coder" {
  fixed_ip = openstack_compute_instance_v2.coder.access_ip_v4
}

resource "openstack_networking_floatingip_associate_v2" "coder" {
  floating_ip = openstack_networking_floatingip_v2.coder.address
  port_id = data.openstack_networking_port_v2.coder.id
}

resource "openstack_networking_secgroup_v2" "coder" {
  name = "${var.namespace}-secgroup"
  description = "Security group with SSH, HTTP/S, and PING open to 0.0.0.0/0"
  tags = var.tags
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.coder.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.coder.id
}

resource "openstack_networking_secgroup_rule_v2" "https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.coder.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  port_range_min    = 0
  port_range_max    = 0
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.coder.id
}

resource "openstack_compute_keypair_v2" "coder" {
  name = "${var.namespace}-key"
  public_key = var.public_key
}


###############################
# DNS Config for Coder Service
###############################

data "openstack_dns_zone_v2" "js2_zone" {
    name = "${var.js2_project}.projects.jetstream-cloud.org."
}

resource "openstack_dns_recordset_v2" "coder" {
  zone_id     = data.openstack_dns_zone_v2.js2_zone.id
  name        = "${var.hostname}.${ data.openstack_dns_zone_v2.js2_zone.name}"
  description = "coder server vm"
  ttl         = 3000
  type        = "A"
  records     = [openstack_networking_floatingip_v2.coder.address]
}

resource "openstack_dns_recordset_v2" "star_coder" {
  zone_id     = data.openstack_dns_zone_v2.js2_zone.id
  name        = "*.${var.hostname}.${ data.openstack_dns_zone_v2.js2_zone.name}"
  description = "An example record set"
  ttl         = 3000
  type        = "A"
  records     = [openstack_networking_floatingip_v2.coder.address]
}