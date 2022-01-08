variable "tenancy_ocid" {
  type = string
}
variable "region" {
  type = string
}

variable "user_ocid" {
  type = string
}
variable "fingerprint" {
  type = string
}
variable "private_key_path" {
  type = string
}
variable "private_key_password" {
  type    = string
  default = ""
}

variable "ssh_key_path" {
  type = string
}
variable "ssh_key_pub_path" {
  type = string
}

variable "cluster_public_dns_name" {
  type    = string
  default = null
}

variable "letsencrypt_registration_email" { type = string }
