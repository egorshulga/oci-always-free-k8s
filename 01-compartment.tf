resource "oci_identity_compartment" "tf-compartment" {
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources"
  name           = "tf-compartment"
}

# output "compartment-name" {
#   value = oci_identity_compartment.tf-compartment.name
# }

# output "compartment-OCID" {
#   value = oci_identity_compartment.tf-compartment.id
# }
