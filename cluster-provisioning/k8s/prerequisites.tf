locals {
  script = {
    reset-iptables  = file("${path.module}/scripts/reset-iptables.sh")
    install-kubeadm = file("${path.module}/scripts/install-kubeadm.sh")
  }
  cluster_public_address = var.cluster_public_dns_name != null ? var.cluster_public_dns_name : var.cluster_public_ip
}
