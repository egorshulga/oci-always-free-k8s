variable "compartment_id" { type = string }
variable "ssh_key_pub" { type = string }

variable "leader" {
  type = object({
    shape         = string
    image         = string
    ocpus         = number
    memory_in_gbs = number
    hostname      = string
    subnet_id     = string
  })
}

variable "workers" {
  type = object({
    count         = number
    shape         = string
    image         = string
    ocpus         = number
    memory_in_gbs = number
    base_hostname = string
    subnet_id     = string
  })
}
