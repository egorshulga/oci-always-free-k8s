variable "tenancy_ocid" {
  type      = string
  nullable  = false
  sensitive = true
}

variable "region" {
  type     = string
  nullable = false
}

variable "leader-ssh-key-pub" {
  type     = string
  nullable = false
}
