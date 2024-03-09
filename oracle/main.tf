
# ---
#  https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-compartment/01-summary.htm
resource "oci_identity_compartment" "tf-compartment" {
  # Required
  compartment_id = var.tenancy_ocid
  description    = "Compartment for Terraform resources of Bob in Decoder l'eco."
  name           = "decoderleco_demo1"
}

# Source from https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/identity_availability_domains

data "oci_identity_availability_domains" "ads" {
  compartment_id = oci_identity_compartment.tf-compartment.id
}


############################################
# VCN
############################################

resource "oci_core_vcn" "decoderleco1_vcn_racine" {
  #Required
  compartment_id = oci_identity_compartment.tf-compartment.id
  cidr_blocks    = var.vcn_racine.cidr_blocks
  #Optional
  display_name = var.vcn_racine.display_name
}

############################################
# Public Subnet
############################################

resource "oci_core_subnet" "subnetA_pub" {
  #Required
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.decoderleco1_vcn_racine.id
  cidr_block     = var.subnetA_pub.cidr_block
  #Optional
  display_name               = var.subnetA_pub.display_name
  prohibit_public_ip_on_vnic = !var.subnetA_pub.is_public
  prohibit_internet_ingress  = !var.subnetA_pub.is_public
}

# ---
# https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_subnet#compartment_id
data "oci_core_subnet" "subnetA_pub" {
  #Required
  subnet_id      = oci_core_subnet.subnetA_pub.id
}

# ---
# Enfin cette p***t*** de VM ah les allemands pfiou...
# https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/tf-compute/01-summary.htm
resource "oci_core_instance" "ubuntu_instance" {
  # Required
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  compartment_id      = oci_identity_compartment.tf-compartment.id
  # shape = "VM.Standard2.1"
  shape = "VM.Standard.A1.Flex"
  shape_config {
    memory_in_gbs = 24
    ocpus = 4
  }
  source_details {
    # https://docs.oracle.com/iaas/images/
    source_id   = "ocid1.image.oc1.eu-paris-1.aaaaaaaaf7irdvozuzmwyvbfacdivomj52x65vr6tlg62i6er323sevazdqq" # "ocid1.image.oc1.eu-paris-1.aaaaaaaakdp4a5grz5aaw4dhq4ww5refzzgiv5ao262ygic5poewh6prkm7q"
    source_type = "image"
  }

  # Optional
  display_name = "DecoderLecoCadeauBOB"
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.subnetA_pub.id
  }
  metadata = {
    ssh_authorized_keys = file("~/.decoderleco/compte.oci.a.bobo/id_rsa.pub")
  }
  preserve_boot_volume = false
}