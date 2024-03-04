packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "debian12_base" {
  # ---
  # If you would set 'add_force', to true, then
  # the image will be downloadedagain, even if it
  # was already downloaded.
  # - And you will see in the packer debug logs:
  # packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:12:22 Calling Vagrant CLI: []string{"box", "add", "generic/debian12", "--force", "--provider", "virtualbox"}
  # - 
  add_force    = false
  communicator = "ssh"
  provider     = "virtualbox"
  # source_path  = "./.base.box/debian12base.box"
  source_path  = "generic/debian12" # will use https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box
  # box_name     = "golden_debian12" # set with # # source_path  = "./.base.box/debian12base.box"
  box_name     = "golden_debian12_remote"
  # output_dir   = "./golden/debian12"
  output_dir   = "./golden/debian12_remote"
  insert_key   = true
  template     = "./.vagrant/debian12/Vagrantfile.tpl"
  # ssh_username = "packman"
  # ssh_username = "vagrant"
  # ssh_password = "vagrant"
  # ssh_private_key_file = "~/.vagrant.d/insecure_private_key"

}

build {
  sources = ["source.vagrant.debian12_base"]

  provisioner "shell" {
    # use_env_var_file = true
    # env_var_file = ".shell/.build/.env"
    # execute_command = "echo 'vagrant' | {{ .EnvVarFile }} sudo -S -E bash '{{ .Path }}'"

    # ----
    environment_vars = [
      "LX_USERS_TO_CREATE=pierre jeangarf bob jb",
      "NEW_LX_USERS_EXTRA_GROUPS=docker wheel",
      "DESIRED_DOCKER_COMPOSE_VERSION=2.24.6",
      "DOCKER_DEBIAN_VERSION_STRING=5:25.0.3-1~debian.12~bookworm"
    ]
    # ---
    # - * Only a script file or an inline script can be specified, not both.
    # inline = [
    #   "echo \"Packer inline - DESIRED_DOCKER_VERSION is $DESIRED_DOCKER_VERSION\"",
    #   "echo \"Packer inline - DESIRED_DOCKER_COMPOSE_VERSION is $DESIRED_DOCKER_COMPOSE_VERSION\"",
    # ]
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    # script          = ".shell/.build/setup.sh"
    scripts          = [
      ".shell/.build/setup.sh",
      ".shell/.build/install-containerstack.sh",
      ".shell/.build/install-docker.compose.sh",
      ".shell/.build/create.lx.users.sh"
    ]
  }

}
