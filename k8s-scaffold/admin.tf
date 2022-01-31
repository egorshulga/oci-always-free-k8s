resource "null_resource" "admin" {
  count      = var.debug_create_cluster_admin ? 1 : 0
  depends_on = [null_resource.scaffold]

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
    source      = "${path.module}/apps/admin-user.yaml"
    destination = ".kube/admin-user.yaml"
  }
  provisioner "remote-exec" { inline = ["kubectl apply -f .kube/admin-user.yaml"] }
  provisioner "remote-exec" { inline = ["kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath=\"{.secrets[0].name}\") -o go-template=\"{{.data.token | base64decode}}\" > .kube/admin-token"] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "kubectl delete -f .kube/admin-user.yaml",
    ]
  }
}

data "remote_file" "admin_token" {
  count      = var.debug_create_cluster_admin ? 1 : 0
  depends_on = [null_resource.admin]
  conn {
    user             = var.leader.vm_user
    host             = var.cluster_public_ip
    private_key_path = var.ssh_key_path
  }
  path = ".kube/admin-token"
}

output "admin_token" {
  value = length(data.remote_file.admin_token) > 0 ? data.remote_file.admin_token[0].content : null
}
