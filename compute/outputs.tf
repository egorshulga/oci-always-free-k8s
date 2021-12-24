output "leader_ip" {
  value = local.leader_public_ip
}

output "leader_fqdn" {
  value = local.leader_fqdn
}

output "workers_private_ips" {
  value = oci_core_instance.worker.*.private_ip
}

output "worker" {
  value = oci_core_instance.worker
}
