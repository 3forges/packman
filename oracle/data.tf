# ---
# https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_subnet#compartment_id
data "oci_core_subnet" "subnetA_pub" {
  #Required
  subnet_id = oci_core_subnet.subnetA_pub.id
}

# ---
#  Get root compartment's informations

data "oci_identity_compartment" "root_compartment" {
  #Required
  id = var.tenancy_ocid
}