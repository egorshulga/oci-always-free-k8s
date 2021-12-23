module "vcn" {
  source  = "oracle-terraform-modules/vcn/oci"
  version = "3.1.0"

  compartment_id = var.compartment_id
  region         = var.region

  create_internet_gateway = true
  create_nat_gateway      = true
  vcn_cidrs               = ["10.0.0.0/16"]
  vcn_dns_label           = var.vcn_dns_label
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

resource "oci_core_subnet" "public" {
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.0.0/24"
  route_table_id    = module.vcn.ig_route_id
  security_list_ids = [oci_core_security_list.public.id]
  display_name      = "public-subnet"
  dns_label         = var.public_subnet_dns_label
}

resource "oci_core_security_list" "public" {
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

# Private subnet

resource "oci_core_subnet" "private" {
  compartment_id    = var.compartment_id
  vcn_id            = module.vcn.vcn_id
  cidr_block        = "10.0.1.0/24"
  route_table_id    = module.vcn.nat_route_id
  security_list_ids = [oci_core_security_list.private.id]
  display_name      = "private-subnet"
  dns_label         = var.private_subnet_dns_label
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_id
  vcn_id         = module.vcn.vcn_id
  display_name   = "Security List for Private subnet"
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
