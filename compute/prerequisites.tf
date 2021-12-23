# Availability domain is required for compute instances
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

locals {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

# module "kubeadm-token" {
#   source = "github.com/scholzj/terraform-kubeadm-token"
# }

locals {
  token = "1qqih3.vpeipt4judm83tov" # Predefined token, to avoid instances drop-and-reacreate when possible
  script = {
    reset-iptables  = file("${path.module}/bootstrap/scripts/reset-iptables.sh")
    install-kubeadm = file("${path.module}/bootstrap/scripts/install-kubeadm.sh")
  }
}
