resource "virtualbox_vm" "debian_vm" {
  count = 1
  # name      = format("node-%02d", count.index + 1)
  name = "debian_vm"
  # # https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12
  # image = "https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box"
  image = "http://localhost:3000/package.box"
  # # https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20230607.0.0/AAA
  # image = "https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20180903.0.0/providers/virtualbox.box"
  cpus   = 4
  memory = "8192 mib"
  # user_data = file("${path.module}/user_data")
  # user_data = file("./user_data")

  network_adapter {
    # type           = "hostonly"
    type = "bridged"
    # host_interface = "vboxnet1"
    # host_interface = "enp3s0"
    host_interface = "TP-Link Wireless USB Adapter"
    # device = "enp3s0"
    # device = "HostInterfaceNetworking-TP-Link Wireless USB Adapter"
    # device = "TP-Link Wireless USB Adapter"
  }
}

resource "virtualbox_vm" "minio_vm" {
  count = 1
  # name      = format("node-%02d", count.index + 1)
  name  = "minio_vm"
  image = "http://localhost:3000/package.box"
  # # https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12
  # image = "https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box"
  # # https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20230607.0.0/AAA
  # image = "https://app.vagrantup.com/ubuntu/boxes/bionic64/versions/20180903.0.0/providers/virtualbox.box"
  cpus   = 4
  memory = "4096 mib"
  # user_data = file("${path.module}/user_data")
  # user_data = file("./user_data")

  network_adapter {
    # type           = "hostonly"
    type = "bridged"
    # host_interface = "vboxnet1"
    # host_interface = "enp3s0"
    host_interface = "TP-Link Wireless USB Adapter"
    # device = "enp3s0"
    # device = "HostInterfaceNetworking-TP-Link Wireless USB Adapter"
    # device = "TP-Link Wireless USB Adapter"
  }
  depends_on = [
    virtualbox_vm.debian_vm
  ]
}

