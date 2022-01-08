resource "null_resource" "worker_setup" {
  for_each = { for worker in var.workers : worker.hostname => worker }

  triggers = {
    control_plane_init = null_resource.control_plane_setup.id # Workers will be init'ed after control-plane

    private_ip   = each.value.private_ip
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
  provisioner "remote-exec" {
    inline     = ["mkdir .kube init"]
    on_failure = continue
  }
  provisioner "file" {
    source      = ".terraform/.kube/config-cluster"
    destination = ".kube/config"
  }
  provisioner "file" {
    content     = local.script.reset-iptables
    destination = "/home/ubuntu/init/reset-iptables.sh"
  }
  provisioner "file" {
    content     = local.script.install-kubeadm
    destination = "/home/ubuntu/init/install-kubeadm.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup-worker.sh", {
      leader_url          = var.leader.fqdn,
      k8s_discovery_token = local.k8s_discovery_token,
      node_name           = each.value.hostname,
    })
    destination = "/home/ubuntu/init/setup-worker.sh"
  }
  provisioner "remote-exec" { inline = ["echo 'Running worker init script'"] }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/update-upgrade.sh")] }
  provisioner "remote-exec" { inline = ["chmod 0777 ~/init/*"] }
  provisioner "remote-exec" { inline = ["~/init/reset-iptables.sh"] }
  provisioner "remote-exec" { inline = ["~/init/install-kubeadm.sh"] }
  provisioner "remote-exec" { inline = ["~/init/setup-worker.sh"] }
  provisioner "remote-exec" { inline = ["echo 'Worker init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a worker instance, which was provisioned by Terraform' >> /etc/motd\""] }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl drain ${self.triggers.hostname} --force",
      "kubectl delete node ${self.triggers.hostname}",
    ]
    on_failure = continue
  }
}
