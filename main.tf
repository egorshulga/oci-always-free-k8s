module "governance" {
  source       = "./governance"
  tenancy_ocid = var.tenancy_ocid
}

module "network" {
  source           = "./network"
  compartment_id   = module.governance.compartment_id
  region           = var.region
  vcn_dns_label    = "vcn"
  subnet_dns_label = "subnet"
}

module "compute" {
  source         = "./compute"
  compartment_id = module.governance.compartment_id
  ssh_key_pub    = var.ssh_key_pub
  subnet_id      = module.network.subnet_id

  leader = {
    shape         = "VM.Standard.A1.Flex"
    image         = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    ocpus         = 1
    memory_in_gbs = 6
    hostname      = "leader"
  }
  workers = {
    count         = 0
    shape         = "VM.Standard.A1.Flex"
    image         = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    ocpus         = 1
    memory_in_gbs = 6
    base_hostname = "worker"
  }
}

output "leader_ip" {
  value = module.compute.leader_ip
}

output "leader" {
  value = module.compute.leader
}
