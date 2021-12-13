# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# Retrieve ID for the image
data "oci_core_images" "ubuntu_arm" {
  compartment_id = var.compartment_id
  display_name   = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
}

data "oci_core_images" "ubuntu" {
  compartment_id = var.compartment_id
  display_name   = "Canonical-Ubuntu-20.04-2021.12.01-0"
}
