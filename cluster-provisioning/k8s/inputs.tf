
variable "ssh_key_path" { type = string }
variable "cluster_public_ip" { type = string }
variable "cluster_public_address" {
  type    = string
  default = null
}
variable "load_balancer_id" { type = string }
variable "overwrite_local_kube_config" {
  type = bool
  default = false
}

variable "leader" {
  type = object({
    id         = string
    hostname   = string
    fqdn       = string
    private_ip = string
    vm_user    = string
    ssh_lb = object({
      listener_id = string
      backend_id  = string
    })
  })
}

variable "workers" {
  type = list(object({
    private_ip = string
    hostname   = string
    vm_user    = string
  }))
}
