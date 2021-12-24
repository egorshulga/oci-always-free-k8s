variable "tenancy_ocid" {}
variable "region" {
  default = "eu-amsterdam-1"
}

variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "private_key_password" {
  default = ""
}

variable "ssh_key_path" {}
variable "ssh_key_pub_path" {}
