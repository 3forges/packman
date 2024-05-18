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


# usage : ${data.local_file.MINIO_CSI_DRIVER_ROOT_USER.content}
data "local_file" "MINIO_CSI_DRIVER_ROOT_USER" {
  # filename = "${path.module}/foo.bar"
  filename = "./.MINIO_CSI_DRIVER_ROOT_USER.secret"
}
# ---
# generate: openssl rand -base64 32 > ./.MINIO_CSI_DRIVER_ROOT_PASSWORD.secret
# usage : ${data.local_file.MINIO_CSI_DRIVER_ROOT_PASSWORD.content}
data "local_file" "MINIO_CSI_DRIVER_ROOT_PASSWORD" {
  # filename = "${path.module}/foo.bar"
  filename = "./.MINIO_CSI_DRIVER_ROOT_PASSWORD.secret"
}