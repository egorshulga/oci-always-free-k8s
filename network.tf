module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

  compartment_id = oci_identity_compartment.tf-compartment.name
  region         = var.region

  create_internet_gateway = true
  create_nat_gateway      = true
  create_service_gateway  = true
  vcn_cidrs               = ["10.0.0.0/16"]
  vcn_dns_label           = "vcn"
  vcn_name                = "vcn"
}

locals {
  ICMP = "1"
  TCP  = "6"
  UDP  = "17"
}

# Public subnet

resource "oci_core_subnet" "vcn-public-subnet" {
  compartment_id    = oci_identity_compartment.tf-compartment.name
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.0.0/24"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public-security-list.id]
  display_name      = "public-subnet"
}

resource "oci_core_security_list" "public-security-list" {
  compartment_id = oci_identity_compartment.tf-compartment.name
  vcn_id         = module.vcn.vcn_id
  display_name   = "Security List for Public subnet"
  # Default rules
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = local.TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = local.ICMP
    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
      code = 4
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = local.ICMP
    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    }
  }
}

# Private subnet

resource "oci_core_subnet" "vcn-private-subnet" {
  compartment_id    = oci_identity_compartment.tf-compartment.name
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.1.0/24"
  route_table_id    = module.vcn.nat_route_id
  security_list_ids = [oci_core_security_list.private-security-list.id]
  display_name      = "private-subnet"
}

resource "oci_core_security_list" "private-security-list" {
  compartment_id = oci_identity_compartment.tf-compartment.name
  vcn_id         = module.vcn.vcn_id
  display_name   = "Security List for Private subnet"
  # Default rules
  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
}

# DHCP

resource "oci_core_dhcp_options" "dhcp-options" {
  compartment_id = oci_identity_compartment.tf-compartment.name
  vcn_id         = module.vcn.vcn_id
  options {
    type        = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
}
