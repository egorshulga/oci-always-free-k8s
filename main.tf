module "governance" {
  source       = "./governance"
  tenancy_ocid = var.tenancy_ocid
}

module "network" {
  source                   = "./network"
  compartment_id           = module.governance.compartment_id
  region                   = var.region
  vcn_dns_label            = "vcn"
  public_subnet_dns_label  = "public"
  private_subnet_dns_label = "private"
}

module "compute" {
  source         = "./compute"
  compartment_id = module.governance.compartment_id
  ssh_key_pub    = var.ssh_key_pub

  leader = {
    # shape         = "VM.Standard.A1.Flex"
    # image         = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    shape         = "VM.Standard.E2.1.Micro"
    image         = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus         = 1
    memory_in_gbs = 1
    hostname      = "leader"
    subnet_id     = module.network.public_subnet_id
  }
  workers = {
    count = 1
    # shape         = "VM.Standard.A1.Flex"
    # image         = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    shape         = "VM.Standard.E2.1.Micro"
    image         = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus         = 1
    memory_in_gbs = 1
    base_hostname = "worker"
    subnet_id     = module.network.private_subnet_id
  }
}

output "leader_ip" {
  value = module.compute.leader_ip
}

output "leader_fqdn" {
  value = module.compute.leader_fqdn
}
