resource "null_resource" "worker_setup" {
  count = length(var.workers)

  triggers = {
    control_plane_init = null_resource.control_plane_setup.id # Workers will be init'ed after control-plane

    private_ip   = var.workers[count.index].private_ip
    hostname     = var.workers[count.index].hostname
    vm_user      = var.workers[count.index].vm_user
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
    content     = templatefile("${path.module}/scripts/reset.sh", { hostname = self.triggers.hostname })
    destination = ".kube/reset.sh"
  }
  provisioner "remote-exec" { inline = ["chmod 0777 .kube/reset.sh"] }
  provisioner "file" {
    content     = data.remote_file.kube_config_cluster.content
    destination = ".kube/config"
  }
  provisioner "file" {
    content     = data.remote_file.kube_join_token.content
    destination = ".kube/join-token"
  }
  provisioner "file" {
    content     = data.remote_file.kube_join_hash.content
    destination = ".kube/join-hash"
  }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/update-upgrade.sh")] }
  provisioner "remote-exec" { inline = [local.script.reset-iptables] }
  provisioner "remote-exec" { inline = [local.script.install-kubeadm] }
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/scripts/setup-worker.sh", {
      leader_url = var.leader.fqdn,
      node_name  = var.workers[count.index].hostname,
    })]
  }
  provisioner "remote-exec" { inline = ["echo 'Worker init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a worker instance, which was provisioned by Terraform on $(date)' >> /etc/motd\""] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = [".kube/reset.sh"]
  }
}
