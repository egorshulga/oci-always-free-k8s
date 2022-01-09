variable "ssh_key_path" { type = string }
variable "cluster_public_address" { type = string }
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
