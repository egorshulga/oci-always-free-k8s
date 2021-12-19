# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

locals {
  script = {
    reset-iptables  = file("${path.module}/bootstrap/scripts/reset-iptables.bash")
    install-kubeadm = file("${path.module}/bootstrap/scripts/install-kubeadm.bash")
    setup-control-plane = templatefile("${path.module}/bootstrap/scripts/setup-control-plane.bash", {
      leader-domain-name = "leader.subnet.vcn.oraclevcn.com"
    })
  }
}
