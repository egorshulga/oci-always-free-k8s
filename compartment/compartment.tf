resource "oci_identity_compartment" "main" {
  compartment_id = var.tenancy_ocid
  description    = var.compartment.description
  name           = var.compartment.name
}
