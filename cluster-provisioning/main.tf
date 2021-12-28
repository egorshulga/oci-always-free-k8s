module "governance" {
  source       = "./governance"
  tenancy_ocid = var.tenancy_ocid
}

module "network" {
  source                  = "./network"
  compartment_id          = module.governance.compartment_id
  region                  = var.region
  vcn_dns_label           = "vcn"
  public_subnet_dns_label = "public"
}

module "compute" {
  source           = "./compute"
  compartment_id   = module.governance.compartment_id
  ssh_key_path     = var.ssh_key_path
  ssh_key_pub_path = var.ssh_key_pub_path

  load_balancer_id  = module.network.load_balancer_id
  cluster_public_ip = module.network.reserved_public_ip.ip_address

  leader = {
    # shape = "VM.Standard.A1.Flex"
    # image = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    shape                       = "VM.Standard.E2.1.Micro"
    image                       = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus                       = 1
    memory_in_gbs               = 1
    hostname                    = "leader"
    subnet_id                   = module.network.public_subnet_id
    overwrite_local_kube_config = true
  }
  workers = {
    count = 2
    shape = "VM.Standard.A1.Flex"
    image = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    # shape = "VM.Standard.E2.1.Micro"
    # image = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus         = 1
    memory_in_gbs = 6
    base_hostname = "worker"
    subnet_id     = module.network.public_subnet_id
  }
}

output "cluster_public_ip" {
  value = module.network.reserved_public_ip.ip_address
}
