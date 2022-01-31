# Control-plane setup

resource "null_resource" "control_plane_setup" {
  triggers = {                                  # We can access leader instance after:
    leader_id   = var.leader.id                 # - leader has started,
    lb_listener = var.leader.ssh_lb.listener_id # - LB port 22 listener has been launched,
    lb_backend  = var.leader.ssh_lb.backend_id  # - LB forwarder has set-up.

    vm_user                 = var.leader.vm_user
    cluster_public_address  = var.cluster_public_ip
    cluster_public_dns_name = var.cluster_public_dns_name
    ssh_key_path            = var.ssh_key_path
    hostname                = var.leader.hostname
  }

  connection {
    type        = "ssh"
    user        = self.triggers.vm_user
    host        = self.triggers.cluster_public_address # Load balancer public address. SSH port is configured to point to leader node (see above).
    private_key = file(self.triggers.ssh_key_path)
    timeout     = "5m"
  }
  provisioner "remote-exec" { inline = ["echo 'Running leader init script'"] }
  provisioner "remote-exec" {
    inline     = ["mkdir .kube"]
    on_failure = continue
  }
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/reset.sh", { hostname = self.triggers.hostname })
    destination = ".kube/reset.sh"
  }
  provisioner "remote-exec" { inline = ["chmod 0777 .kube/reset.sh"] }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/update-upgrade.sh")] }
  provisioner "remote-exec" { inline = [local.script.reset-iptables] }
  provisioner "remote-exec" { inline = [local.script.install-kubeadm] }
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/scripts/setup-control-plane.sh", {
      node-name         = var.leader.hostname,
      leader-fqdn       = var.leader.fqdn,
      cluster-public-ip = var.cluster_public_ip,
      cluster-dns-name  = var.cluster_public_dns_name,
    })]
  }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/prepare-kube-config-for-cluster.sh")] }
  provisioner "remote-exec" {
    inline = [templatefile("${path.module}/scripts/prepare-kube-config-for-external.sh", {
      leader-fqdn            = var.leader.fqdn,
      cluster-public-address = local.cluster_public_address,
    })]
  }
  provisioner "remote-exec" { inline = [file("${path.module}/scripts/setup-cluster-network.sh")] }
  provisioner "remote-exec" { inline = ["echo 'Leader init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a leader instance, which was provisioned by Terraform on $(date)' >> /etc/motd\""] }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue
    inline     = [".kube/reset.sh"]
  }
}

data "remote_file" "kube_config_cluster" {
  depends_on = [null_resource.control_plane_setup]
  conn {
    host             = var.cluster_public_ip
    user             = var.leader.vm_user
    private_key_path = var.ssh_key_path
  }
  path = ".kube/config"
}
data "remote_file" "kube_config_external" {
  depends_on = [null_resource.control_plane_setup]
  conn {
    host             = var.cluster_public_ip
    user             = var.leader.vm_user
    private_key_path = var.ssh_key_path
  }
  path = ".kube/config-external"
}
data "remote_file" "kube_join_token" {
  depends_on = [null_resource.control_plane_setup]
  conn {
    host             = var.cluster_public_ip
    user             = var.leader.vm_user
    private_key_path = var.ssh_key_path
  }
  path = ".kube/join-token"
}
data "remote_file" "kube_join_hash" {
  depends_on = [null_resource.control_plane_setup]
  conn {
    host             = var.cluster_public_ip
    user             = var.leader.vm_user
    private_key_path = var.ssh_key_path
  }
  path = ".kube/join-hash"
}

resource "local_file" "kube_config" {
  sensitive_content = data.remote_file.kube_config_external.content
  filename          = ".terraform\\.kube\\config-external"
}

resource "null_resource" "save_kube_config" {
  triggers = {
    external_kube_config                = local_file.kube_config.id
    windows_overwrite_local_kube_config = var.windows_overwrite_local_kube_config
  }
  provisioner "local-exec" {
    command = var.windows_overwrite_local_kube_config ? "copy /Y .terraform\\.kube\\config-external %USERPROFILE%\\.kube\\config" : "echo Kube config is available locally: .terraform/.kube/config-external"
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
