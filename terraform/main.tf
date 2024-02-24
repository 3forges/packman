resource "virtualbox_vm" "debian_vm" {
  count = 1
  # name      = format("node-%02d", count.index + 1)
  name   = "debian_vm"
  image  = "https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20180903.0.0/providers/virtualbox.box"
  cpus   = 4
  memory = "8192 mib"
  # user_data = file("${path.module}/user_data")
  user_data = file("./user_data")
  network_adapter {
    # type           = "hostonly"
    type = "bridge"
    # host_interface = "vboxnet1"
  }
}


