locals {
  script = {
    reset-iptables  = file("${path.module}/scripts/reset-iptables.sh")
    install-kubeadm = file("${path.module}/scripts/install-kubeadm.sh")
  }
}
