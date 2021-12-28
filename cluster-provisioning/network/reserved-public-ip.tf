resource "oci_core_public_ip" "reserved" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "reserved-ip"
}
