data "oci_core_images" "workers" {
  compartment_id = var.compartment_id
  display_name   = var.workers.image
}

resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  display_name = "${var.workers.base_hostname}-${count.index}"
  count        = var.workers.count

  shape = var.workers.shape
  shape_config {
    ocpus         = var.workers.ocpus
    memory_in_gbs = var.workers.memory_in_gbs
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.workers.images[0].id
  }

  create_vnic_details {
    assign_public_ip          = false
    subnet_id                 = var.workers.subnet_id
    assign_private_dns_record = true
    hostname_label            = "${var.workers.base_hostname}-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub_path)
    user_data           = data.template_cloudinit_config.worker.rendered
  }
}

data "template_cloudinit_config" "worker" {
  base64_encode = true
  gzip          = true
  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/bootstrap/cloud-init-worker.yml", {
      reset-iptables  = local.script.reset-iptables,
      install-kubeadm = local.script.install-kubeadm,
      setup-worker    = local.setup-worker,
    })
  }
}

locals {
  setup-worker = templatefile("${path.module}/bootstrap/scripts/setup-worker.sh", {
    leader-fqdn = local.leader_fqdn,
    token       = local.token,
  })
}
