resource "null_resource" "k8s_infrastructure" {
  triggers = {
    vm_user                = var.leader.vm_user
    cluster_public_address = var.cluster_public_address
    ssh_key_path           = var.ssh_key_path
  }

  connection {
    type        = "ssh"
    user        = self.triggers.vm_user
    host        = self.triggers.cluster_public_address # Load balancer public ip. SSH port is configured to point to leader node (see above).
    private_key = file(self.triggers.ssh_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline     = ["mkdir .kube"]
    on_failure = continue
  }
  provisioner "file" {
    source      = "${path.module}/bootstrap/ingress-controller.yaml"
    destination = ".kube/ingress-controller.yaml"
  }
  provisioner "file" {
    source      = "${path.module}/bootstrap/cert-manager.yaml"
    destination = ".kube/cert-manager.yaml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/bootstrap/letsencrypt-issuer.yaml", {
      letsencrypt_registration_email = var.letsencrypt_registration_email
    })
    destination = ".kube/letsencrypt-issuer.yaml"
  }
  provisioner "file" {
    content = templatefile("${path.module}/bootstrap/dashboard.yaml", {
      host = var.cluster_public_address
    })
    destination = ".kube/dashboard.yaml"
  }

  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/ingress-controller.yaml"] }
  provisioner "remote-exec" { inline = ["kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s"] }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/cert-manager.yaml"] }
  provisioner "remote-exec" { inline = ["kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s"] }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/letsencrypt-issuer.yaml"] }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/dashboard.yaml"] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "kubectl delete -f .kube/ingress-controller.yaml",
      "kubectl delete -f .kube/cert-manager.yaml",
      "kubectl delete -f .kube/letsencrypt-issuer.yaml",
      "kubectl delete -f .kube/dashboard.yaml",
    ]
  }
}
