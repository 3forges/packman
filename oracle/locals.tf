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
    \n
    Primary-PublicIP:  %{if i.public_ip != ""}${i.public_ip~}%{else}N/A%{endif~}
    \n
    Primary-PrivateIP: ${i.private_ip~}
    \n
    SSH into the VM:   ssh -i ${var.vm_ssh_auth_desired_keypair.private_key_file} ${var.vm_ssh_auth_desired_keypair.username}@${i.public_ip~}
    \n
    Go to the Minio Admin UI : http://${i.public_ip~}:9001
    EOT
  ]
  # ubuntu_vm_ssh_details = [
  #   // display name, Primary VNIC Public/Private IP for each instance
  #   for keypair in [var.vm_ssh_auth_desired_keypair] : <<EOT
  #   SSH into the VM:   ssh -Ti ${keypair.private_key_file} ubuntu@${i.public_ip~}
  #   EOT
  # ]
}