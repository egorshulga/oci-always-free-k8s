variable "tenancy_ocid" {
  type = string
}

variable "compartment" {
  type = object({
    name        = string
    description = string
  })
}
