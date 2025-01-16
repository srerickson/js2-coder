output "url" {
  value = "https://${local.server_fqdn}"
}

output "public_ip" {
  value = openstack_networking_floatingip_v2.coder.address
}