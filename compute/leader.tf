data "oci_core_images" "leader" {
  compartment_id = var.compartment_id
  display_name   = var.leader.image
}

data "oci_core_subnet" "leader" {
  subnet_id = var.leader.subnet_id
}

data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.leader.vcn_id
}

locals {
  leader_fqdn = "${var.leader.hostname}.${data.oci_core_subnet.leader.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}

resource "oci_core_instance" "leader" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  display_name = var.leader.hostname

  shape = var.leader.shape
  shape_config {
    ocpus         = var.leader.ocpus
    memory_in_gbs = var.leader.memory_in_gbs
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.leader.images[0].id
  }

  create_vnic_details {
    assign_public_ip          = true
    subnet_id                 = var.leader.subnet_id
    assign_private_dns_record = true
    hostname_label            = var.leader.hostname
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub_path)
    # user_data = data.template_cloudinit_config.leader.rendered
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = self.public_ip
    private_key = file(var.ssh_key_path)
    timeout     = "1m"
  }
  provisioner "remote-exec" {
    inline = ["mkdir init"]
  }
  provisioner "file" {
    content     = local.script.reset-iptables
    destination = "/home/ubuntu/init/reset-iptables.sh"
  }
  provisioner "file" {
    content     = local.script.install-kubeadm
    destination = "/home/ubuntu/init/install-kubeadm.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/bootstrap/scripts/setup-control-plane.sh", {
      leader-fqdn      = local.leader_fqdn,
      token            = local.token,
      leader-public-ip = self.public_ip,
    })
    destination = "/home/ubuntu/init/setup-control-plane.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'Running leader cloud-init script'",
      "sudo apt-get update --yes",
      "sudo apt-get upgrade --yes",
      "chmod 0777 ~/init/*",
      "~/init/reset-iptables.sh",
      "~/init/install-kubeadm.sh",
      "~/init/setup-control-plane.sh",
      "echo 'Leader cloud-init script complete'",
      "sudo bash -c \"echo 'This is a leader instance, which was provisioned by Terraform' >> /etc/motd\"",
    ]
  }
}
