data "oci_core_images" "workers" {
  compartment_id = var.compartment_id
  display_name   = var.workers.image
}

resource "oci_core_instance" "worker" {
  compartment_id      = var.compartment_id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name

  count        = var.workers.count
  display_name = "${var.workers.base_hostname}-${count.index}"

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
}

# Load Balancer - HTTP

# resource "oci_network_load_balancer_backend_set" "workers_http" {
#   network_load_balancer_id = var.load_balancer_id
#   name                     = "workers_http"
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = true
#   health_checker {
#     protocol = "TCP"
#     port     = 22
#   }
#   lifecycle {
#     ignore_changes = [backends]
#   }
# }

# resource "oci_network_load_balancer_backend" "worker_http" {
#   count                    = var.workers.count
#   backend_set_name         = oci_network_load_balancer_backend_set.workers_http.name
#   network_load_balancer_id = var.load_balancer_id
#   name                     = "worker-${count.index}-http"
#   port                     = 30080 # Nginx ingress-controller service NodePort
#   target_id                = oci_core_instance.worker[count.index].id
# }

# resource "oci_network_load_balancer_listener" "workers_http" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.workers_http.name
#   name                     = "workers_http"
#   network_load_balancer_id = var.load_balancer_id
#   port                     = 80
#   protocol                 = "TCP"
# }

# # Load Balancer - HTTPS

# resource "oci_network_load_balancer_backend_set" "workers_https" {
#   network_load_balancer_id = var.load_balancer_id
#   name                     = "workers_https"
#   policy                   = "FIVE_TUPLE"
#   is_preserve_source       = true
#   health_checker {
#     protocol = "TCP"
#     port     = 22
#   }
#   lifecycle {
#     ignore_changes = [backends]
#   }
# }

# resource "oci_network_load_balancer_backend" "worker_https" {
#   count                    = var.workers.count
#   backend_set_name         = oci_network_load_balancer_backend_set.workers_https.name
#   network_load_balancer_id = var.load_balancer_id
#   name                     = "worker-${count.index}-https"
#   port                     = 30443 # Nginx ingress-controller service NodePort
#   target_id                = oci_core_instance.worker[count.index].id
# }

# resource "oci_network_load_balancer_listener" "workers_https" {
#   default_backend_set_name = oci_network_load_balancer_backend_set.workers_https.name
#   name                     = "workers_https"
#   network_load_balancer_id = var.load_balancer_id
#   port                     = 443
#   protocol                 = "TCP"
# }
