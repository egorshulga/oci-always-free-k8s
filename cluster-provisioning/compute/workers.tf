data "oci_core_images" "workers" {
  compartment_id = var.compartment_id
  display_name   = var.workers.image
}

resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  display_name = "${var.workers.base_hostname}-${count.index}"
  count        = var.workers.count

  shape = var.workers.shape
  shape_config {
    ocpus         = var.workers.ocpus
    memory_in_gbs = var.workers.memory_in_gbs
  }
  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.workers.images[0].id
  }

  create_vnic_details {
    assign_public_ip          = false
    subnet_id                 = var.workers.subnet_id
    assign_private_dns_record = true
    hostname_label            = "${var.workers.base_hostname}-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_key_pub_path)
  }

  extended_metadata = {
    vm_user      = local.vm_user
    bastion_host = var.cluster_public_ip
    ssh_key_path = var.ssh_key_path
  }

  connection {
    type                = "ssh"
    user                = self.extended_metadata.vm_user
    host                = self.private_ip
    private_key         = file(self.extended_metadata.ssh_key_path)
    bastion_user        = self.extended_metadata.vm_user
    bastion_host        = self.extended_metadata.bastion_host
    bastion_private_key = file(self.extended_metadata.ssh_key_path)
    timeout             = "1m"
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
    content = templatefile("${path.module}/bootstrap/scripts/setup-worker.sh", {
      leader_url          = local.leader_fqdn,
      k8s_discovery_token = local.k8s_discovery_token,
    })
    destination = "/home/ubuntu/init/setup-worker.sh"
  }
  provisioner "remote-exec" { inline = ["echo 'Running worker init script'"] }
  provisioner "remote-exec" { inline = ["sudo apt-get update --yes"] }
  provisioner "remote-exec" { inline = ["sudo apt-get upgrade --yes"] }
  provisioner "remote-exec" { inline = ["chmod 0777 ~/init/*"] }
  provisioner "remote-exec" { inline = ["~/init/reset-iptables.sh"] }
  provisioner "remote-exec" { inline = ["~/init/install-kubeadm.sh"] }
  provisioner "remote-exec" { inline = ["~/init/setup-worker.sh"] }
  provisioner "remote-exec" { inline = ["echo 'Worker init script complete'"] }
  provisioner "remote-exec" { inline = ["sudo bash -c \"echo 'This is a worker instance, which was provisioned by Terraform' >> /etc/motd\""] }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl drain ${self.hostname_label} --force",
      "kubectl delete node ${self.hostname_label}",
    ]
    on_failure = continue
  }
}
