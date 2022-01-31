resource "null_resource" "scaffold" {
  triggers = {
    vm_user                 = var.leader.vm_user
    cluster_public_ip       = var.cluster_public_ip
    cluster_public_dns_name = var.cluster_public_dns_name
    ssh_key_path            = var.ssh_key_path
  }

  connection {
    type        = "ssh"
    user        = self.triggers.vm_user
    host        = self.triggers.cluster_public_ip # Load balancer public ip. SSH port is configured to point to leader node (see above).
    private_key = file(self.triggers.ssh_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline     = ["mkdir .kube"]
    on_failure = continue
  }
  provisioner "file" {
    source      = "${path.module}/apps/ingress-controller.yaml"
    destination = ".kube/ingress-controller.yaml"
  }
  provisioner "file" {
    source      = "${path.module}/apps/cert-manager.yaml"
    destination = ".kube/cert-manager.yaml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/apps/letsencrypt-issuer.yaml", {
      letsencrypt_registration_email = var.letsencrypt_registration_email
    })
    destination = ".kube/letsencrypt-issuer.yaml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/apps/dashboard.yaml", {
      cluster_public_dns_name = var.cluster_public_dns_name
    })
    destination = ".kube/dashboard.yaml"
  }

  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/ingress-controller.yaml"] }
  provisioner "remote-exec" { inline = ["kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s"] }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/cert-manager.yaml"] }
  provisioner "remote-exec" { inline = [
    "until kubectl apply -f .kube/letsencrypt-issuer.yaml", # We need to wait until cert-manager completes initialization.
    "do",                                                   # Unfortunately, there is no API to wait for it programmatically,
    "  echo Retrying creation of letsencrypt cert issuer",  # that is why we try to create letsencrypt cert issuer,
    "  sleep 10",                                           # until it succeedes (kubectl apply issuer fails with
    "done",                                                 # 'failed calling webhook' error till cert-manager is initialized).
  ] }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/dashboard.yaml"] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "kubectl delete -f .kube/dashboard.yaml",
      "kubectl delete -f .kube/letsencrypt-issuer.yaml",
      "kubectl delete -f .kube/cert-manager.yaml",
      "kubectl delete -f .kube/ingress-controller.yaml",
    ]
  }
}
