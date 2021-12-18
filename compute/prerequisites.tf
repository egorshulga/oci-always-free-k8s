# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
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

locals {
  script = {
    reset-iptables      = file("${path.module}/bootstrap/scripts/reset-iptables.bash")
    install-kubeadm     = file("${path.module}/bootstrap/scripts/install-kubeadm.bash")
    setup-control-plane = templatefile("${path.module}/bootstrap/scripts/setup-control-plane.bash", {
      leader-domain-name = "leader.subnet.vcn.oraclevcn.com"
    })
  }
}
