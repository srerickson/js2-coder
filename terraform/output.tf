output "coder_ipv4_address" {
  value = openstack_networking_floatingip_v2.dcn_coder.address
}

output "coder_host" {
  value = openstack_dns_recordset_v2.coder.name
}