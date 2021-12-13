variable "tenancy_ocid" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "region" {
  type     = string
  nullable = false
}

variable "leader_ssh_key_pub" {
  type     = string
  nullable = false
}
