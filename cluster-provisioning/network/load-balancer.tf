resource "oci_network_load_balancer_network_load_balancer" "load_balancer" {
  compartment_id                 = var.compartment_id
  display_name                   = "load-balancer"
  subnet_id                      = oci_core_subnet.public.id
  is_private                     = false
  is_preserve_source_destination = false
  reserved_ips {
    id = oci_core_public_ip.reserved.id
  }
}
