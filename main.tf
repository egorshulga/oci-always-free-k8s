module "compartment" {
  source       = "./compartment"
  tenancy_ocid = var.tenancy_ocid
  compartment = {
    name        = "terraformed"
    description = "Compartment for Terraform'ed resources"
  }
}

module "network" {
  source                   = "./network"
  compartment_id           = module.compartment.id
  region                   = var.region
  vcn_dns_label            = "vcn"
  public_subnet_dns_label  = "public"
  provision_private_subnet = true
  private_subnet_dns_label = "private"
}

module "compute" {
  source              = "./compute"
  compartment_id      = module.compartment.id
  ssh_key_pub_path    = var.ssh_key_pub_path
  load_balancer_id    = module.network.load_balancer_id
  availability_domain = 0

  leader = {
    shape = "VM.Standard.A1.Flex"
    image = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    # shape = "VM.Standard.E2.1.Micro"
    # image = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus            = 1
    memory_in_gbs    = 3
    hostname         = "leader"
    subnet_id        = module.network.private_subnet_id
    assign_public_ip = false
  }
  workers = {
    count = 3
    shape = "VM.Standard.A1.Flex"
    image = "Canonical-Ubuntu-20.04-aarch64-2021.12.01-0"
    # shape = "VM.Standard.E2.1.Micro"
    # image = "Canonical-Ubuntu-20.04-2021.12.01-0"
    ocpus            = 1
    memory_in_gbs    = 7
    base_hostname    = "worker"
    subnet_id        = module.network.private_subnet_id
    assign_public_ip = false
  }
}

module "k8s" {
  source                              = "./k8s"
  ssh_key_path                        = var.ssh_key_path
  cluster_public_ip                   = module.network.reserved_public_ip.ip_address
  cluster_public_dns_name             = var.cluster_public_dns_name
  load_balancer_id                    = module.network.load_balancer_id
  leader                              = module.compute.leader
  workers                             = module.compute.workers
  windows_overwrite_local_kube_config = var.windows_overwrite_local_kube_config
}

module "k8s_scaffold" {
  source                         = "./k8s-scaffold"
  depends_on                     = [module.k8s]
  ssh_key_path                   = var.ssh_key_path
  cluster_public_ip              = module.network.reserved_public_ip.ip_address
  cluster_public_dns_name        = var.cluster_public_dns_name
  letsencrypt_registration_email = var.letsencrypt_registration_email
  load_balancer_id               = module.network.load_balancer_id
  leader                         = module.compute.leader
  workers                        = module.compute.workers
  debug_create_cluster_admin     = var.debug_create_cluster_admin
}

output "cluster_public_ip" {
  value = module.network.reserved_public_ip.ip_address
}

output "cluster_public_address" {
  value = var.cluster_public_dns_name
}

output "admin_token" {
  value = module.k8s_scaffold.admin_token
}
