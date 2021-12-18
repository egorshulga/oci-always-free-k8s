resource "oci_core_instance" "leader" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

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
    user_data           = data.template_cloudinit_config.leader_cloud_init.rendered
  }
}

data "template_cloudinit_config" "leader_cloud_init" {
  base64_encode = true
  gzip          = true
  part {
    content = templatefile("${path.module}/bootstrap/cloud-init-leader.yml", {
      reset-iptables      = local.script.reset-iptables,
      install-kubeadm     = local.script.install-kubeadm,
      setup-control-plane = local.script.setup-control-plane,
    })
  }
}

output "leader_ip" {
  value = oci_core_instance.leader.public_ip
}

output "leader" {
  value = oci_core_instance.leader
}
