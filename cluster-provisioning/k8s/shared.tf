locals {
  k8s_discovery_token = "1qqih3.vpeipt4judm83tov" # Predefined token, to avoid instances drop-and-reacreate when possible.
  script = {
    reset-iptables  = file("${path.module}/scripts/reset-iptables.sh")
    install-kubeadm = file("${path.module}/scripts/install-kubeadm.sh")
  }
}
