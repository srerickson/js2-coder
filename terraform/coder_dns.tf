###############################
# DNS Config for Coder Service
###############################

data "openstack_dns_zone_v2" "js2_zone" {
    name = "${var.js2_project}.projects.jetstream-cloud.org."
}

resource "openstack_dns_recordset_v2" "coder" {
  zone_id     = data.openstack_dns_zone_v2.js2_zone.id
  name        = "coder.${ data.openstack_dns_zone_v2.js2_zone.name}"
  description = "An example record set"
  ttl         = 3000
  type        = "A"
  records     = [openstack_networking_floatingip_v2.dcn_coder.address]
}

resource "openstack_dns_recordset_v2" "star_coder" {
  zone_id     = data.openstack_dns_zone_v2.js2_zone.id
  name        = "*.coder.${ data.openstack_dns_zone_v2.js2_zone.name}"
  description = "An example record set"
  ttl         = 3000
  type        = "A"
  records     = [openstack_networking_floatingip_v2.dcn_coder.address]
}
