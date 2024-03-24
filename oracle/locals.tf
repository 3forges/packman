# locals {
#   ubuntu_vm_details = [
#     // display name, Primary VNIC Public/Private IP for each instance
#     for i in oci_core_instance.ubuntu_vm : <<EOT
#     ${~i.display_name~}
#     Primary-PublicIP: %{if i.public_ip != ""}${i.public_ip~}%{else}N/A%{endif~}
#     Primary-PrivateIP: ${i.private_ip~}
#     EOT
#   ]
# }

locals {
  ubuntu_vm_details = [
    // display name, Primary VNIC Public/Private IP for each instance
    for i in [oci_core_instance.ubuntu_vm] : <<EOT
    ${~i.display_name~}
    Primary-PublicIP: %{if i.public_ip != ""}${i.public_ip~}%{else}N/A%{endif~}
    Primary-PrivateIP: ${i.private_ip~}
    EOT
  ]
}