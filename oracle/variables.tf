variable "region" {
  default = "eu-paris-1"
  type    = string
}
variable "tenancy_ocid" {
  default = "ocid1.tenancy.oc1..aaaaaaaawdca5brwcdw7mng3nxbvlx2pqxhnxm6gs3alrsi7visngutjtzvq"
  type    = string
}
variable "user_ocid" {
  default = "ocid1.user.oc1..aaaaaaaagcrmipneaw5vucavguw5c3rywx5mfcetefnsyxvebmdyywbedu2q"
  type    = string
}
variable "fingerprint" {
  default = "7c:5c:65:4b:fc:c2:77:be:4e:0c:5c:9c:f0:34:89:9c"
  type    = string
}
variable "private_key_path" {
  default = "/Users/Utilisateur/.oci/clef_oracle_cloud.pem"
  type    = string
}


# [DEFAULT]
# user=ocid1.user.oc1..aaaaaaaagcrmipneaw5vucavguw5c3rywx5mfcetefnsyxvebmdyywbedu2q
# fingerprint=7c:5c:65:4b:fc:c2:77:be:4e:0c:5c:9c:f0:34:89:9c
# tenancy=ocid1.tenancy.oc1..aaaaaaaawdca5brwcdw7mng3nxbvlx2pqxhnxm6gs3alrsi7visngutjtzvq
# region=eu-paris-1
# key_file=<path to your private keyfile> # TODO


variable "vcn_racine" {
  description = "The Decoder L'eco racine VCN."
  default = {
    cidr_blocks : ["10.23.0.0/20"]
    display_name : "decoderleco1_vcn_racine"
  }
}

variable "vm_ssh_auth_desired_keypair" {
  description = "The path to the private and public keys your generated for ssh into your VM."
  default = {
    public_key_file : "~/.decoderleco/compte.oci.a.bobo/id_rsa.pub"
    private_key_file : "~/.decoderleco/compte.oci.a.bobo/id_rsa"
  }
}


variable "subnetA_pub" {
  description = "The subnet exposing publicly the VM on internet."
  default = {
    cidr_block : "10.23.11.0/24"
    display_name : "IC_pub_snet-A"
    is_public : true
    route_table : {
      display_name = "subnetA_pub_routeTable"
      description  = "subnetA_pub routeTable"
    }
  }
}

variable "internet_gateway_A" {
  description = "The details of the internet gateway"
  default = {
    display_name : "IC_IG-A"
    ig_destination = "0.0.0.0/0"
  }
}