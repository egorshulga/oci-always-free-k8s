variable "compartment_id" {}
variable "ssh_key_pub" {}
variable "subnet_id" {}

variable "workers_count" {
  default = 1
}
variable "workers_arm_count" {
  default = 1
}
