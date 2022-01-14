variable "compartment_id" { type = string }
variable "ssh_key_pub_path" { type = string }
variable "load_balancer_id" { type = string }

variable "leader" {
  type = object({
    shape            = string
    image            = string
    ocpus            = number
    memory_in_gbs    = number
    hostname         = string
    subnet_id        = string
    assign_public_ip = bool
  })
}

variable "workers" {
  type = object({
    count            = number
    shape            = string
    image            = string
    ocpus            = number
    memory_in_gbs    = number
    base_hostname    = string
    subnet_id        = string
    assign_public_ip = bool
  })
}

variable "availability_domain" {
  type    = number
  default = 0
}
