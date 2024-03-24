
# ---
#  https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/first-compartment/01-summary.htm
resource "oci_identity_compartment" "first-compartment" {
  # Required
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources of Bob in Decoder l'eco."
  name           = "decoderleco_demo1"
}

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains

data "oci_identity_availability_domains" "ads" {
  compartment_id = oci_identity_compartment.first-compartment.id
}


############################################
# VCN
############################################

resource "oci_core_vcn" "decoderleco1_vcn_racine" {
  #Required
  compartment_id = oci_identity_compartment.first-compartment.id
  cidr_blocks    = var.vcn_racine.cidr_blocks
  #Optional
  display_name = var.vcn_racine.display_name
}

############################################
# Public Subnet
############################################

resource "oci_core_subnet" "subnetA_pub" {
  #Required
  compartment_id = oci_identity_compartment.first-compartment.id
  vcn_id         = oci_core_vcn.decoderleco1_vcn_racine.id
  cidr_block     = var.subnetA_pub.cidr_block
  #Optional
  display_name               = var.subnetA_pub.display_name
  prohibit_public_ip_on_vnic = !var.subnetA_pub.is_public
  prohibit_internet_ingress  = !var.subnetA_pub.is_public
}

# ---
# Enfin cette p***t*** de VM ah les allemands pfiou...
# https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-compute/01-summary.htm
resource "oci_core_instance" "ubuntu_vm" {
  # Required
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.first-compartment.id
  # shape = "VM.Standard2.1"
  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 24
    ocpus         = 4
  }
  source_details {
    # https://docs.oracle.com/iaas/images/
    # https://github.com/3forges/packman/blob/feature/packer/full/appliances/lifecycle/oracle/OciShapesImagesCompatibilityMatrix.ipynb
    source_id   = "ocid1.image.oc1.eu-paris-1.aaaaaaaadvmvakdix5qznsbs5fk2cervokzm36kcm6xppv6w2nfqne6s3gna" # "Canonical-Ubuntu-22.04-Minimal-aarch64-2024.02.18-0"
    source_type = "image"
  }

  # Optional
  display_name = "DecoderLecoCadeauBOB"
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.subnetA_pub.id
  }
  metadata = {
    ssh_authorized_keys = file(var.vm_ssh_auth_desired_keypair.public_key_file)
  }
  preserve_boot_volume = false
}


############################################
# IMORTANT: 
# Without 
#  - Internet Gateways
#  - and NAT Gateways
#  - and Route Table
# you would not be able to SSH into the VM's Public IP
############################################

############################################
# Internet Gateways and NAT Gateways
############################################

resource "oci_core_internet_gateway" "the_internet_gateway" {
  compartment_id = oci_identity_compartment.first-compartment.id
  vcn_id         = oci_core_vcn.decoderleco1_vcn_racine.id
  display_name   = var.internet_gateway_A.display_name
}


############################################
# Route Tables
############################################

resource "oci_core_default_route_table" "the_route_table" {
  #Required
  compartment_id             = oci_identity_compartment.first-compartment.id
  manage_default_resource_id = oci_core_vcn.decoderleco1_vcn_racine.default_route_table_id
  # Optional
  display_name = var.subnetA_pub.route_table.display_name
  dynamic "route_rules" {
    for_each = [true]
    content {
      destination       = var.internet_gateway_A.ig_destination
      description       = var.subnetA_pub.route_table.description
      network_entity_id = oci_core_internet_gateway.the_internet_gateway.id
    }
  }
}

########################################
# Ingress Rules for HTTP-based apps
########################################



resource "oci_core_security_list" "root_compartment_security_list" {
  #Required
  compartment_id = var.tenancy_ocid
  vcn_id         = oci_core_vcn.decoderleco1_vcn_racine.id

  #Optional
  // defined_tags = {"Operations.CostCenter"= "42"}
  display_name = "Décoder l'éco Security Rules for root compartment"

  freeform_tags = { "Department" = "Décoder L'éco" }
  // inspired by https://github.com/oracle/terraform-provider-oci/blob/e95fac9bee135b539b6db97395984677373231ff/infrastructure/resource_discovery/transient/core.tf#L441C1-L470C4
  // allow inbound minio webui traffic
  ingress_security_rules {
    description = "allow inbound minio webui traffic"
    protocol    = "6" // "6" is for tcp, I could simply try "all", https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list#protocol
    source      = "0.0.0.0/0"
    stateless   = false

    tcp_options {
      min = 9001
      max = 9001

      # source_port_range {
      #   min = 100
      #   max = 65534
      # }
    }
  }
  // allow inbound jupyterlab webui traffic
  ingress_security_rules {
    description = "allow inbound jupyterlab webui traffic"
    protocol    = "6" // "6" is for tcp, I could simply try "all", https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list#protocol
    source      = "0.0.0.0/0"
    stateless   = false

    tcp_options {
      min = 8888
      max = 8888

      # source_port_range {
      #   min = 100
      #   max = 65534
      # }
    }
  }
  //  // allow inbound icmp traffic of a specific type
  //  ingress_security_rules {
  //    description = "allow inbound icmp traffic"
  //    protocol    = 1
  //    source      = "0.0.0.0/0"
  //    stateless   = true
  //
  //    icmp_options {
  //      type = 3
  //      code = 4
  //    }
  //  }
}

resource "oci_core_security_list" "first_compartment_security_list" {
  #Required
  compartment_id = oci_identity_compartment.first-compartment.id
  vcn_id         = oci_core_vcn.decoderleco1_vcn_racine.id

  #Optional
  // defined_tags = {"Operations.CostCenter"= "42"}
  display_name = "Décoder l'éco Security Rules for First compartment, inside the root compartment."

  freeform_tags = { "Department" = "Décoder L'éco" }
  // inspired by https://github.com/oracle/terraform-provider-oci/blob/e95fac9bee135b539b6db97395984677373231ff/infrastructure/resource_discovery/transient/core.tf#L441C1-L470C4
  // allow inbound minio webui traffic
  ingress_security_rules {
    description = "allow inbound minio webui traffic"
    protocol    = "6" // "6" is for tcp, I could simply try "all", https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list#protocol
    source      = "0.0.0.0/0"
    stateless   = false

    tcp_options {
      min = 9001
      max = 9001

      # source_port_range {
      #   min = 100
      #   max = 65534
      # }
    }
  }
  // allow inbound jupyterlab webui traffic
  ingress_security_rules {
    description = "allow inbound jupyterlab webui traffic"
    protocol    = "6" // "6" is for tcp, I could simply try "all", https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list#protocol
    source      = "0.0.0.0/0"
    stateless   = false

    tcp_options {
      min = 8888
      max = 8888

      # source_port_range {
      #   min = 100
      #   max = 65534
      # }
    }
  }
  //  // allow inbound icmp traffic of a specific type
  //  ingress_security_rules {
  //    description = "allow inbound icmp traffic"
  //    protocol    = 1
  //    source      = "0.0.0.0/0"
  //    stateless   = true
  //
  //    icmp_options {
  //      type = 3
  //      code = 4
  //    }
  //  }
}