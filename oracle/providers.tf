terraform {
  # specify provider
  required_providers {
    # put preview provider in ~/.terraform.d/plugins/terraform.local/local/oci/4.80.1/darwin_amd64
    oci = {
      source  = "oracle/oci"
      version = ">= 3.0.0"
    }
  }
  # specify terraform version
  # required_version = ">= 0.12.31"
  required_version = ">= 1.3.0"
}

provider "oci" {
  # version          = ">= 3.0.0"
  region           = var.region
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
}