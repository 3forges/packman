packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "debian12_base" {
  add_force    = true
  communicator = "ssh"
  provider     = "virtualbox"
  # source_path  = "./.base.box/debian12base.box"
  source_path  = "https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box"
  box_name     = "golden_debian12"
  output_dir   = "./golden/debian12"
  insert_key   = true
  template     = "./.vagrant/debian12/Vagrantfile.tpl"
  # ssh_username = "packman"
  # ssh_password = "packman"
  # ssh_private_key_file = "./packer/.ssh.packman/id_rsa"

}

build {
  sources = ["source.vagrant.debian12_base"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = ".shell/.build/setup.sh"
  }

}
