# Outputs for compartment

output "compartment-name" {
  value = oci_identity_compartment.first-compartment.name
}

output "compartment-OCID" {
  value = oci_identity_compartment.first-compartment.id
}


# The "name" of the availability domain to be used for the compute instance.
output "name-of-first-availability-domain" {
  value = data.oci_identity_availability_domains.ads.availability_domains[0].name
}

output "ubuntu_vm_summary" {
  description = "Private and Public IPs of the Compute instance."
  value       = local.ubuntu_vm_details
}