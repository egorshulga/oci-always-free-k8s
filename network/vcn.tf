module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

  compartment_id = var.compartment_id
  region         = var.region

  create_internet_gateway = true
  create_nat_gateway      = var.provision_private_subnet
  create_service_gateway  = var.provision_private_subnet
  vcn_cidrs               = ["10.0.0.0/16"]
  vcn_dns_label           = var.vcn_dns_label
  vcn_name                = "vcn"
}

# DHCP

resource "oci_core_dhcp_options" "dhcp_options" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}
