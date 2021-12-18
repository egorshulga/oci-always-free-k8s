module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

  compartment_id = var.compartment_id
  region         = var.region

  create_internet_gateway = true
  vcn_cidrs               = ["10.0.0.0/16"]
  vcn_dns_label           = "vcn"
  vcn_name                = "vcn"
}

locals {
  # https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
  protocol = {
    ICMP = "1"
    TCP  = "6"
    UDP  = "17"
  }
}

# Public subnet

resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.0.0/24"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public_security_list.id]
  display_name      = "public-subnet"
  dns_label         = "subnet"
}

resource "oci_core_security_list" "public_security_list" {
  compartment_id = var.compartment_id
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
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.TCP
    tcp_options {
      min = 22
      max = 22
    }
  }
  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = local.protocol.ICMP
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
    protocol    = local.protocol.ICMP
    # For ICMP type and code see: https://www.iana.org/assignments/icmp-parameters/icmp-parameters.xhtml
    icmp_options {
      type = 3
    }
  }
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
