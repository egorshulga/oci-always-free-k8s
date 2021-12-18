module "governance" {
  source       = "./governance"
  tenancy_ocid = var.tenancy_ocid
}

module "network" {
  source         = "./network"
  compartment_id = module.governance.compartment_id
  region         = var.region
}

module "compute" {
  source         = "./compute"
  compartment_id = module.governance.compartment_id
  ssh_key_pub    = var.ssh_key_pub
  subnet_id      = module.network.subnet_id

  workers_count = 0
}

output "leader_ip" {
  value = module.compute.leader_ip
}

output "leader" {
  value = module.compute.leader
}
