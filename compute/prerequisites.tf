# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

data "oci_core_subnet" "subnet" {
  subnet_id = var.subnet_id
}

data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.subnet.vcn_id
}

locals {
  leader_fqdn = "${var.leader.hostname}.${data.oci_core_subnet.subnet.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}

locals {
  script = {
    reset-iptables  = file("${path.module}/bootstrap/scripts/reset-iptables.sh")
    install-kubeadm = file("${path.module}/bootstrap/scripts/install-kubeadm.sh")
    setup-control-plane = templatefile("${path.module}/bootstrap/scripts/setup-control-plane.sh", {
      leader-domain-name = local.leader_fqdn
    })
  }
}
