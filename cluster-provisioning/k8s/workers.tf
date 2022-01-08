resource "null_resource" "worker_setup" {
  for_each = { for worker in var.workers : worker.hostname => worker }

  triggers = {
    control_plane_init = null_resource.control_plane_setup.id # Workers will be init'ed after control-plane

    private_ip   = each.value.private_ip
    hostname     = each.value.hostname
    vm_user      = each.value.vm_user
    bastion_host = var.cluster_public_ip
    ssh_key_path = var.ssh_key_path
  }

  connection {
    type                = "ssh"
    host                = self.triggers.private_ip
    user                = self.triggers.vm_user
    private_key         = file(self.triggers.ssh_key_path)
    bastion_host        = self.triggers.bastion_host
    bastion_user        = self.triggers.vm_user
    bastion_private_key = file(self.triggers.ssh_key_path)
    timeout             = "5m"
  }
  provisioner "remote-exec" { inline = ["echo 'Running worker init script'"] }
  provisioner "remote-exec" {
    inline     = ["mkdir .kube"]
    on_failure = continue
  }
  provisioner "file" {
    source      = ".terraform/.kube/config-cluster"
    destination = ".kube/config"
  }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/update-upgrade.sh")] }
  provisioner "remote-exec" { inline = [local.script.reset-iptables] }
  provisioner "remote-exec" { inline = [local.script.install-kubeadm] }
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/scripts/setup-worker.sh", {
      leader_url          = var.leader.fqdn,
      k8s_discovery_token = local.k8s_discovery_token,
      node_name           = each.value.hostname,
    })]
  }
  provisioner "remote-exec" { inline = ["echo 'Worker init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a worker instance, which was provisioned by Terraform' >> /etc/motd\""] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "kubectl drain ${self.triggers.hostname} --force --ignore-daemonsets",
      "kubectl delete node ${self.triggers.hostname}",
      "sudo kubeadm reset --force",
    ]
  }
}
