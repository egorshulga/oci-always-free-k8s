variable "tenancy_ocid" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "region" {
  type     = string
  nullable = false
}
