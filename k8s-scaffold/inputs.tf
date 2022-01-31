variable "ssh_key_path" { type = string }
variable "cluster_public_ip" { type = string }
variable "cluster_public_dns_name" { type = string }
variable "letsencrypt_registration_email" { type = string }

variable "load_balancer_id" { type = string }

variable "leader" {
  type = object({
    vm_user = string
  })
}

variable "workers" {
  type = list(object({
    id = string
  }))
}

variable "debug_create_cluster_admin" {
  type    = bool
  default = false
}
