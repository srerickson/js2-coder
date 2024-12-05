output "coder_ipv4_address" {
  value = openstack_networking_floatingip_v2.coder.address
}

output "coder_host" {
  value = openstack_dns_recordset_v2.coder.name
}

# output "coder_credential_id" {
#   value = openstack_identity_application_credential_v3.coder.id
# }

# output "coder_credential_secret" {
#   value = openstack_identity_application_credential_v3.coder.secret
#   sensitive = true
# }