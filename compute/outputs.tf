output "leader_ip" {
  value = oci_core_instance.leader.public_ip
}

output "leader_fqdn" {
  value = local.leader_fqdn
}
