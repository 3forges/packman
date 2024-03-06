# output "IPAddr" {
#   value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
# }
# 
# output "IPAddr_2" {
#   value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 2)
# }

output "debian_vm_IPAddr" {
  # value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
  value = virtualbox_vm.debian_vm[0].network_adapter.0.ipv4_address
}

output "minio_vm_IPAddr" {
  # value = element(virtualbox_vm.node.*.network_adapter.0.ipv4_address, 1)
  value = virtualbox_vm.minio_vm[0].network_adapter.0.ipv4_address
}