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
    assign_public_ip          = var.leader.assign_public_ip
    subnet_id                 = var.leader.subnet_id
    assign_private_dns_record = true
    hostname_label            = var.leader.hostname
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub_path)
  }

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  leader_fqdn = "${var.leader.hostname}.${data.oci_core_subnet.leader.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}

# Load Balancer - ssh to leader

resource "oci_network_load_balancer_backend_set" "leader_ssh" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_ssh"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 22
  }
}

resource "oci_network_load_balancer_backend" "leader_ssh" {
  backend_set_name         = oci_network_load_balancer_backend_set.leader_ssh.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_ssh"
  port                     = 22
  target_id                = oci_core_instance.leader.id
}

resource "oci_network_load_balancer_listener" "leader_ssh" {
  default_backend_set_name = oci_network_load_balancer_backend_set.leader_ssh.name
  name                     = "leader_ssh"
  network_load_balancer_id = var.load_balancer_id
  port                     = 22
  protocol                 = "TCP"
}
