resource "oci_core_instance" "leader" {
  compartment_id      = var.compartment_id
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
    assign_public_ip          = true
    subnet_id                 = var.subnet_id
    assign_private_dns_record = true
    hostname_label            = "leader"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub)
    user_data           = base64encode(file("${path.module}/bootstrap/leader.sh"))
  }
}

output "leader-ip" {
  value = oci_core_instance.leader.public_ip
}
