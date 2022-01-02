data "oci_core_images" "leader" {
  compartment_id = var.compartment_id
  display_name   = var.leader.image
}

data "oci_core_subnet" "leader" {
  subnet_id = var.leader.subnet_id
}

data "oci_core_vcn" "vcn" {
  vcn_id = data.oci_core_subnet.leader.vcn_id
}

resource "oci_core_instance" "leader" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain

  display_name = var.leader.hostname

  shape = var.leader.shape
  shape_config {
    ocpus         = var.leader.ocpus
    memory_in_gbs = var.leader.memory_in_gbs
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.leader.images[0].id
  }

  create_vnic_details {
    assign_public_ip          = false
    subnet_id                 = var.leader.subnet_id
    assign_private_dns_record = true
    hostname_label            = var.leader.hostname
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub_path)
  }
}

locals {
  leader_fqdn = "${var.leader.hostname}.${data.oci_core_subnet.leader.dns_label}.${data.oci_core_vcn.vcn.dns_label}.oraclevcn.com"
}

# Load Balancer - ssh to leader

resource "oci_network_load_balancer_backend_set" "leader_ssh" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_ssh"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 22
  }
}

resource "oci_network_load_balancer_backend" "leader_ssh" {
  backend_set_name         = oci_network_load_balancer_backend_set.leader_ssh.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "leader_ssh"
  port                     = 22
  target_id                = oci_core_instance.leader.id
}

resource "oci_network_load_balancer_listener" "leader_ssh" {
  default_backend_set_name = oci_network_load_balancer_backend_set.leader_ssh.name
  name                     = "leader_ssh"
  network_load_balancer_id = var.load_balancer_id
  port                     = 22
  protocol                 = "TCP"
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
  target_id                = oci_core_instance.leader.id
}

resource "oci_network_load_balancer_listener" "control_plane_api" {
  default_backend_set_name = oci_network_load_balancer_backend_set.control_plane_api.name
  name                     = "control_plane_api"
  network_load_balancer_id = var.load_balancer_id
  port                     = 6443
  protocol                 = "TCP"
}

# Leader setup

resource "null_resource" "leader_setup" {
  triggers = {
    leader_id   = oci_core_instance.leader.id
    lb_backend  = oci_network_load_balancer_backend.leader_ssh.id
    lb_listener = oci_network_load_balancer_listener.leader_ssh.id

    vm_user           = local.vm_user
    ssh_key_path      = var.ssh_key_path
    hostname          = var.leader.hostname
    cluster_public_ip = var.cluster_public_ip
  }

  connection {
    type        = "ssh"
    user        = self.triggers.vm_user
    host        = self.triggers.cluster_public_ip # Load balancer public ip. SSH port is configured to point to leader node (see above).
    private_key = file(self.triggers.ssh_key_path)
    timeout     = "1m"
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
    content     = file("${path.module}/bootstrap/scripts/prepare-kube-config-for-cluster.sh")
    destination = "/home/ubuntu/init/prepare-kube-config-for-cluster.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/bootstrap/scripts/prepare-kube-config-for-external.sh", {
      leader-fqdn            = local.leader_fqdn,
      cluster-public-address = var.cluster_dns_name == null ? var.cluster_public_ip : var.cluster_dns_name,
    })
    destination = "/home/ubuntu/init/prepare-kube-config-for-external.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/bootstrap/scripts/setup-control-plane.sh", {
      k8s_discovery_token = local.k8s_discovery_token,
      leader-fqdn         = local.leader_fqdn,
      cluster-public-ip   = var.cluster_public_ip,
      cluster-dns-name    = var.cluster_dns_name
    })
    destination = "/home/ubuntu/init/setup-control-plane.sh"
  }
  provisioner "file" {
    content     = file("${path.module}/bootstrap/scripts/setup-cluster-network.sh")
    destination = "/home/ubuntu/init/setup-cluster-network.sh"
  }
  provisioner "remote-exec" { inline = ["echo 'Running leader init script'"] }
  provisioner "remote-exec" { inline = ["sudo apt-get update --yes"] }
  provisioner "remote-exec" { inline = ["sudo apt-get upgrade --yes"] }
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
  provisioner "local-exec" { command = "scp -i ${var.ssh_key_path} -o StrictHostKeyChecking=off ${local.vm_user}@${var.cluster_public_ip}:~/.kube/config .terraform/.kube/config-cluster" }
  provisioner "local-exec" { command = "scp -i ${var.ssh_key_path} -o StrictHostKeyChecking=off ${local.vm_user}@${var.cluster_public_ip}:~/.kube/config-external .terraform/.kube/config-external" }
  provisioner "local-exec" { command = var.leader.overwrite_local_kube_config ? "copy /Y .terraform\\.kube\\config-external %USERPROFILE%\\.kube\\config" : "echo Kube config is available locally: .terraform/.kube/config-external" }

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
