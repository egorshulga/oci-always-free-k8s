resource "oci_core_public_ip" "reserved" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = "reserved-ip"
  lifecycle {
    ignore_changes = [private_ip_id] # Terraform removes load balancer IP assignment on subsequent updates, so we ignore this field.
    prevent_destroy = true
  }
}
