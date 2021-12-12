# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = oci_identity_compartment.tf-compartment.id
}

# Retrieve ID for the image
data "oci_core_images" "ubuntu_arm" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
}

resource "oci_core_instance" "leader" {
  compartment_id      = oci_identity_compartment.tf-compartment.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  display_name = "leader"

  shape = "VM.Standard.A1.Flex"
  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm.images[0].id
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.vcn-public-subnet.id
  }

  metadata = {
    ssh_authorized_keys = file(var.leader-ssh-key-pub)
  }
}

output "leader-ip" {
  value = oci_core_instance.leader.public_ip
}
