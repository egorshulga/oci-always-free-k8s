# Control-plane setup

resource "null_resource" "control_plane_setup" {
  triggers = {                                  # We can access leader instance after:
    leader_id   = var.leader.id                 # - leader has started,
    lb_listener = var.leader.ssh_lb.listener_id # - LB port 22 listener has been launched,
    lb_backend  = var.leader.ssh_lb.backend_id  # - LB forwarder has set-up.

    vm_user           = var.leader.vm_user
    ssh_key_path      = var.ssh_key_path
    hostname          = var.leader.hostname
    cluster_public_ip = var.cluster_public_ip
  }

  connection {
    type        = "ssh"
    user        = self.triggers.vm_user
    host        = self.triggers.cluster_public_ip # Load balancer public ip. SSH port is configured to point to leader node (see above).
    private_key = file(self.triggers.ssh_key_path)
    timeout     = "5m"
  }
  provisioner "remote-exec" {
    inline     = ["mkdir init"]
    on_failure = continue
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
    content     = file("${path.module}/scripts/prepare-kube-config-for-cluster.sh")
    destination = "/home/ubuntu/init/prepare-kube-config-for-cluster.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/scripts/prepare-kube-config-for-external.sh", {
      leader-fqdn            = var.leader.fqdn,
      cluster-public-address = var.cluster_public_address != null ? var.cluster_public_address : var.cluster_public_ip,
    })
    destination = "/home/ubuntu/init/prepare-kube-config-for-external.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/scripts/setup-control-plane.sh", {
      k8s_discovery_token = local.k8s_discovery_token,
      node-name           = var.leader.hostname,
      leader-fqdn         = var.leader.fqdn,
      cluster-public-ip   = var.cluster_public_ip,
      cluster-dns-name    = var.cluster_public_address
    })
    destination = "/home/ubuntu/init/setup-control-plane.sh"
  }
  provisioner "file" {
    content     = file("${path.module}/scripts/setup-cluster-network.sh")
    destination = "/home/ubuntu/init/setup-cluster-network.sh"
  }
  provisioner "remote-exec" { inline = ["echo 'Running leader init script'"] }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/update-upgrade.sh")] }
  provisioner "remote-exec" { inline = ["chmod 0777 ~/init/*"] }
  provisioner "remote-exec" { inline = ["~/init/reset-iptables.sh"] }
  provisioner "remote-exec" { inline = ["~/init/install-kubeadm.sh"] }
  provisioner "remote-exec" { inline = ["~/init/setup-control-plane.sh"] }
  provisioner "remote-exec" { inline = ["~/init/prepare-kube-config-for-cluster.sh"] }
  provisioner "remote-exec" { inline = ["~/init/prepare-kube-config-for-external.sh"] }
  provisioner "remote-exec" { inline = ["~/init/setup-cluster-network.sh"] }
  provisioner "remote-exec" { inline = ["echo 'Leader init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a leader instance, which was provisioned by Terraform' >> /etc/motd\""] }

  provisioner "local-exec" {
    command    = "mkdir .terraform\\.kube"
    on_failure = continue
  }
  provisioner "local-exec" { command = "scp -i ${var.ssh_key_path} -o StrictHostKeyChecking=off ${var.leader.vm_user}@${var.cluster_public_ip}:~/.kube/config .terraform/.kube/config-cluster" }
  provisioner "local-exec" { command = "scp -i ${var.ssh_key_path} -o StrictHostKeyChecking=off ${var.leader.vm_user}@${var.cluster_public_ip}:~/.kube/config-external .terraform/.kube/config-external" }
  provisioner "local-exec" { command = var.overwrite_local_kube_config ? "copy /Y .terraform\\.kube\\config-external %USERPROFILE%\\.kube\\config" : "echo Kube config is available locally: .terraform/.kube/config-external" }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline = [
      "kubectl drain ${self.triggers.hostname} --force",
      "kubectl delete node ${self.triggers.hostname} --force",
      "sudo kubeadm reset --force",
    ]
  }
}

# Load Balancer - kubectl to control plane

resource "oci_network_load_balancer_backend_set" "control_plane_api" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "control_plane_api"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol    = "HTTPS"
    port        = 6443
    url_path    = "/livez"
    return_code = 200
  }
}

resource "oci_network_load_balancer_backend" "control_plane_api" {
  backend_set_name         = oci_network_load_balancer_backend_set.control_plane_api.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "control_plane_api"
  port                     = 6443
  target_id                = var.leader.id
}

resource "oci_network_load_balancer_listener" "control_plane_api" {
  default_backend_set_name = oci_network_load_balancer_backend_set.control_plane_api.name
  name                     = "control_plane_api"
  network_load_balancer_id = var.load_balancer_id
  port                     = 6443
  protocol                 = "TCP"
}
