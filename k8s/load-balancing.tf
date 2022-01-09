# Load Balancer - HTTP

resource "oci_network_load_balancer_backend_set" "workers_http" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "workers_http"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 22
  }
  lifecycle {
    ignore_changes = [backends]
  }
}

resource "oci_network_load_balancer_backend" "worker_http" {
  count                    = length(var.workers)
  backend_set_name         = oci_network_load_balancer_backend_set.workers_http.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker-${count.index}-http"
  port                     = 30080 # Nginx ingress-controller service NodePort
  target_id                = var.workers[count.index].id
}

resource "oci_network_load_balancer_listener" "workers_http" {
  default_backend_set_name = oci_network_load_balancer_backend_set.workers_http.name
  name                     = "workers_http"
  network_load_balancer_id = var.load_balancer_id
  port                     = 80
  protocol                 = "TCP"
}

# Load Balancer - HTTPS

resource "oci_network_load_balancer_backend_set" "workers_https" {
  network_load_balancer_id = var.load_balancer_id
  name                     = "workers_https"
  policy                   = "FIVE_TUPLE"
  is_preserve_source       = true
  health_checker {
    protocol = "TCP"
    port     = 22
  }
  lifecycle {
    ignore_changes = [backends]
  }
}

resource "oci_network_load_balancer_backend" "worker_https" {
  count                    = length(var.workers)
  backend_set_name         = oci_network_load_balancer_backend_set.workers_https.name
  network_load_balancer_id = var.load_balancer_id
  name                     = "worker-${count.index}-https"
  port                     = 30443 # Nginx ingress-controller service NodePort
  target_id                = var.workers[count.index].id
}

resource "oci_network_load_balancer_listener" "workers_https" {
  default_backend_set_name = oci_network_load_balancer_backend_set.workers_https.name
  name                     = "workers_https"
  network_load_balancer_id = var.load_balancer_id
  port                     = 443
  protocol                 = "TCP"
}
