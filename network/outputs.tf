output "public_subnet_id" {
  value = oci_core_subnet.public.id
}

output "private_subnet_id" {
  value = length(oci_core_subnet.private) > 0 ? oci_core_subnet.private[0].id : null
}

output "reserved_public_ip" {
  value = {
    id         = oci_core_public_ip.reserved.id
    ip_address = oci_core_public_ip.reserved.ip_address
  }
}

output "load_balancer_id" {
  value = oci_network_load_balancer_network_load_balancer.load_balancer.id
}
