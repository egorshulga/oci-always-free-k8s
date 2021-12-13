module "network" {
  source         = "./network"
  compartment_id = oci_identity_compartment.tf_compartment.id
  region         = var.region
}

module "compute" {
  source         = "./compute"
  compartment_id = oci_identity_compartment.tf_compartment.id
  ssh_key_pub    = var.ssh_key_pub
  subnet_id      = module.network.subnet_id

  workers_count     = 1
  workers_arm_count = 2
}
