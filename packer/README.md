# The Packer part

In the analysis of the terraform provider to provision our debian VM, we ended up with a fully functional debian VM, nevertheless lacking an SSH Key inside.

Our terraform recipe:

* Downloads a vagrant box, from the vagrant boxes registry, in the `~/.terraform/virtualbox/gold/virtualbox` folder.
* copies all files from the `~/.terraform/virtualbox/gold/virtualbox` folder, into a subfolder of the `~/.terraform/virtualbox/machine/` folder.
* Imports the OVF appliance foundin the  the `~/.terraform/virtualbox/machine/` folder, to create a VirtualBox VM.
* then applies the changes using `VBoxManage`
* and finally boots up the VM.

The purpose of this recipe, is:

* To build, using packer, a new vagrant box, relying on an already existing one in the local filesystem
* The new vagrant box will give a VirutlaBox VM:
  * with an SSH Key inside
  * with Docker, and Docker compose installed
  * with either of:
    * Either one single big disk (120GB) duynamically allocated the actual host disk space.
    * Or with, if possible, two virtual disks, instead of just one: both dynamically allocated, one is 20GB, the second 40GB for the docker `data-root`. AFter abit of work, it seems to methat it would be much more natural to use [the `virtualbox-iso` packer builder](https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox/latest/components/builder/iso), to set up such fine disk setup. See also other [packer virtualbox integrations](https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox)

To achieve our goal, we will use Packer's [vagrant](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant) builder. That builder we are very interested in, because of two perfect properties for our case:

* we preferable do not want to install vagrant: unforutnaltely, the vagrant packer builder does require to install vagrant.
* we would like to just modify an eisting Vagrant Box.

## (Re)-Install (upgrade) Packer

### On Windows AMD64

#### Git bash for windows

In a git bash for windows shell session, as administrator:

* To install packer, run:

```bash
choco install packer
```

* To upgrade your packer installtion, run:

```bash
choco upgrade packer
```

## Install Vagrant

* Windows AMD64:

```bash

export DESIRED_VAGRANT_VERSION="2.4.1"
export VAGRANT_BIN_DWNLD_LINK="https://releases.hashicorp.com/vagrant/${DESIRED_VAGRANT_VERSION}/vagrant_${DESIRED_VAGRANT_VERSION}_windows_amd64.msi"

curl -LO ${VAGRANT_BIN_DWNLD_LINK}


ls -alh ./vagrant_${DESIRED_VAGRANT_VERSION}_windows_amd64.msi

mkdir -p ~/.bin/vagrant/${DESIRED_VAGRANT_VERSION}/

msiexec -qn -norestart -i "vagrant_${DESIRED_VAGRANT_VERSION}_windows_amd64.msi" VAGRANTAPPDIR="${HOME}/.bin/vagrant/${DESIRED_VAGRANT_VERSION}/"
# - >
# >>> You would then have to restart
# >>> your computer, for the vagrant installation to be complete.
# - >
# mkdir -p ~/.bin/vagrant/${DESIRED_VAGRANT_VERSION}/
# unzip ./ccc -d ~/.bin/vagrant/${DESIRED_VAGRANT_VERSION}/

```

## How to run

* First,run the init, to resolve the `packer` build dependencies (and prepare the SSH key to install into the VM):

```bash
packer init ./packer.pkr.hcl
# ---
# - output:
# ---
# $ packer init ./packer.pkr.hcl
# Installed plugin github.com/hashicorp/vagrant v1.1.2 in "C:/Users/Utilisateur/AppData/Roaming/packer.d/plugins/github.com/hashicorp/vagrant/packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe"

# ---
# -
# ---

chmod +x ./.shell/.utils/*.sh
./.shell/.utils/prepare.sh
```

* Then, run the build:

```bash
export PACKER_LOG=debug
packer build ./packer.pkr.hcl
```

* Spin up the resulting VM:

```bash
cd ./golden/debian12_remote
vagrant up --provider virtualbox

# --- To stop the VM:
# vagrant halt

# --- To destroy the VM:
# vagrant destroy -f

```

* Clean everything up, except the huge base vagrant box  downloaded from `app.vagrantup.com`:

```bash
# ---
#  Beware: 'golden_debian12_remote' is 
#  exactly the value of the 
#  'box_name', in the 
#  'packer.pkr.hcl' file
ls -alh ~/.vagrant.d/boxes/golden_debian12_remote || true

vagrant box remove golden_debian12_remote

ls -alh ~/.vagrant.d/boxes/golden_debian12_remote || true

# ---
#  Beware: './golden/debian12_remote' is 
#  exactly the value of the 
#  'output_dir', in the 
#  'packer.pkr.hcl' file
rm -fr ./golden/debian12_remote
```

* vagrant login:

```bash

$ vagrant login --token ${MY_SECRET_TOKEN}
WARNING: This command has been deprecated and aliased to `vagrant cloud auth login`
Translation missing: en.cloud_command.token_saved
Translation missing: en.cloud_command.check_logged_in

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer (feature/set/ssh/key)
$ vagrant cloud auth --help
Usage: vagrant cloud auth <subcommand> [<args>]

Authorization with Vagrant Cloud

Available subcommands:
     login
     logout
     whoami

For help on any individual subcommand run `vagrant cloud auth <subcommand> -h`
        --[no-]color                 Enable or disable color output
        --machine-readable           Enable machine readable output
    -v, --version                    Display Vagrant version
        --debug                      Enable debug output
        --timestamp                  Enable timestamps on log output
        --debug-timestamp            Enable debug output with timestamps
        --no-tty                     Enable non-interactive output

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer (feature/set/ssh/key)
$ vagrant cloud auth whoami
Currently logged in as Jean-Baptiste-Lasselle


```

* publish the newly created vagrant box:

```bash
# https://github.com/magma/magma/blob/f7b296b754b70b3b8949f442b0aae3c10de9a63a/orc8r/tools/packer/vagrant-box-upload.sh#L31
$ #vagrant cloud auth login --token "$VAGRANT_CLOUD_TOKEN"
$ vagrant cloud auth whoami
$ vagrant cloud box create --description "Vagrant box for a debian 12 vm,with docker and docker compose installed, designed for the https://github.com/decoder-leco contributors" -s "debian 12 + docker + docker-compose" decoderleco/debian12-docker
$ vagrant cloud box update --description "Vagrant box for a debian 12 vm, with docker and docker compose installed, designed for the https://github.com/decoder-leco contributors" -s "debian 12 + docker + docker-compose" decoderleco/debian12-docker
$ vagrant cloud publish -f -a amd64 --description "Vagrant box for a debian 12 vm,with docker and docker compose installed, designed for the https://github.com/decoder-leco contributors" --version-description "first published version of the docker reference stack" decodeleco/debian12-docker 0.0.1-alpha virtualbox ./golden/debian12_remote/package.box

$ vagrant cloud publish -f --no-release -a amd64 --description "Vagrant box for a debian 12 vm,with docker and docker compose installed, designed for the https://github.com/decoder-leco contributors" -c "8a0559661b8822f4b67fdd24c4cff3fbd38db26719f55d1627e32bd220c1098bf7a243c70ea80faab8b6d1d3e35bdabb7ed42156652b3e175f3cbb6ef157d94c" -C "sha512" --version-description "first published version of the docker reference stack" decodeleco/debian12-docker 0.0.1-alpha virtualbox ./golden/debian12_remote/package.box

$ vagrant cloud publish -f -r -a amd64 --description "Vagrant box for a debian 12 vm,with docker and docker compose installed, designed for the https://github.com/decoder-leco contributors" -c "8a0559661b8822f4b67fdd24c4cff3fbd38db26719f55d1627e32bd220c1098bf7a243c70ea80faab8b6d1d3e35bdabb7ed42156652b3e175f3cbb6ef157d94c" -C "sha512" --version-description "first published version of the docker reference stack" decodeleco/debian12-docker 0.0.1-alpha virtualbox ./golden/debian12_remote/package.box
```

https://github.com/hashicorp/vagrant/issues/12714
https://github.com/hashicorp/vagrant/issues/12714
https://github.com/hashicorp/vagrant/issues/13349

## The journal of analysis

Here you can read all the analysis work I did, day by day, to achieve the result I get in this repository.

I wrote it like a classic diary of a traveler.

And I started from:

* [The official packer vagrant builder page](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant)
* And the `packer.pkr.json` file you will find in the same folder than this `README.md`.

_Have a nice journey._

First, I upgraded my `packer` installation, and I got to version:

```bash
$ date && packer --version
Fri Mar  1 20:02:50     2024
Packer v1.10.0

Your version of Packer is out of date! The latest version
is 1.10.1. You can update by downloading from www.packer.io/downloads
```

Following instructions in the [vagrant builder docs](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant), I created the Json packer configuration, and then converted it to HCL:

```bash

export CONFIGURED_SOURCE_PATH="ubuntu/focal64"
export CONFIGURED_SOURCE_PATH="ubuntu/focal64"

cat <<EOF >./packer.pkr.json
{
    "provisioners": [
      {
        "type": "shell",
        "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'",
        "script": "scripts/setup.sh"
      }
    ],
    "builders": [
      {
        "communicator": "ssh",
        "source_path": "ubuntu/focal64",
        "provider": "virtualbox",
        "add_force": true,
        "type": "vagrant"
      }
    ]
  }
EOF
packer hcl2_upgrade -output-file=packer.pkr.hcl packer.pkr.json
```

Finally, I created a `./.base.box` folder, where I copied all the files of the Vagrant box downloaded by the `terra-farm/terraform-provider-virtualbox` from `~/.terraform/virtualbox/gold/virtualbox/`:

```bash
mkdir -p ./.base.box/content
cp -fr ~/.terraform/virtualbox/gold/virtualbox/* ./.base.box/content/

# ---
# A VagrantBox is just a gzip tarball, as of
# the golang source code file 'image.go' of
# the terraform provider, and
#  https://developer.hashicorp.com/vagrant/docs/boxes/format
# - 
# 

# ---
# - [tar + gzip] = [tar -z]
# tar -zcvf ./.base.box/box.tar.gz ./.base.box/content
tar -zcvf ./.base.box/debian12base.box ./.base.box/content
# --- ---
# -- check the content of
# -  the box (a gzip tarball):
# --
# tar -tf ./.base.box/debian12base.box
tar -tf ./.base.box/debian12base.box
# -- ----

export CONFIGURED_SOURCE_PATH="ubuntu/focal64"
export CONFIGURED_SOURCE_PATH="./.base.box/debian12base.box"

cat <<EOF >./packer.pkr.json
{
    "provisioners": [
      {
        "type": "shell",
        "execute_command": "echo 'vagrant' | {{.Vars}} sudo -S -E bash '{{.Path}}'",
        "script": ".shell/.build/setup.sh"
      }
    ],
    "builders": [
      {
        "communicator": "ssh",
        "source_path": "${CONFIGURED_SOURCE_PATH}",
        "provider": "virtualbox",
        "add_force": true,
        "type": "vagrant"
      }
    ]
  }
EOF
rm ./packer.pkr.hcl
packer hcl2_upgrade -output-file=packer.pkr.hcl packer.pkr.json

```

#### First try

resulted with an error, `SSH Port was not properly retrieved from SSHConfig`:

```bash
$ packer build ./packer.pkr.hcl
vagrant.debian12_base: output will be in this color.

==> vagrant.debian12_base: Retrieving Box
==> vagrant.debian12_base: Trying ./.base.box/debian12base.box
==> vagrant.debian12_base: Trying ./.base.box/debian12base.box
==> vagrant.debian12_base: ./.base.box/debian12base.box => C:/Users/Utilisateur/packman/packer/.base.box/debian12base.box
==> vagrant.debian12_base: Creating a Vagrantfile in the build directory...
==> vagrant.debian12_base: Adding box using vagrant box add ...
    vagrant.debian12_base: (this can take some time if we need to download the box)
==> vagrant.debian12_base: Calling Vagrant Up (this can take some time)...
==> vagrant.debian12_base: destroying Vagrant box...
==> vagrant.debian12_base: Deleting output directory...
Build 'vagrant.debian12_base' errored after 3 minutes 55 seconds: error: SSH Port was not properly retrieved from SSHConfig.

==> Wait completed after 3 minutes 55 seconds

==> Some builds didn't complete successfully and had errors:
--> vagrant.debian12_base: error: SSH Port was not properly retrieved from SSHConfig.

==> Builds finished but no artifacts were created.

```

So I modified my `packer.pkr.hcl`, to add box_name and output_dir:

```bash
mkdir -p ./golden/debian12
touch ./golden/debian12/README.md
touch ./golden/README.md

cat <<EOF >./packer.pkr.hcl
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
  source_path  = "./.base.box/debian12base.box"
  box_name     = "golden_debian12"
  output_dir   = "./golden/debian12"
}

build {
  sources = ["source.vagrant.debian12_base"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = ".shell/.build/setup.sh"
  }

}
EOF

```

I then had an error specifyi that my output directory already exist:

```bash
$ packer build ./packer.pkr.hcl
vagrant.debian12_base: output will be in this color.

==> vagrant.debian12_base: Retrieving Box
==> vagrant.debian12_base: Trying ./.base.box/debian12base.box
==> vagrant.debian12_base: Trying ./.base.box/debian12base.box
==> vagrant.debian12_base: ./.base.box/debian12base.box => C:/Users/Utilisateur/packman/packer/.base.box/debian12base.box
Build 'vagrant.debian12_base' errored after 297 milliseconds 581 microseconds: Output directory exists: ./golden/debian12

Use the force flag to delete it prior to building.

==> Wait completed after 297 milliseconds 581 microseconds

==> Some builds didn't complete successfully and had errors:
--> vagrant.debian12_base: Output directory exists: ./golden/debian12

Use the force flag to delete it prior to building.

==> Builds finished but no artifacts were created.

```

So I destroyed the folder by running `rm -fr golden/debian12/`, and launched the packer build again: to fall again on that error `ccc`

That's where i googled that error, and found this blog post: <https://bsago.me/tech-notes/create-vagrant-boxes-with-packer#:~:text=error%3A%20SSH%20Port%20was%20not,one%20of%20many%20other%20things>

It was dealing with another problem, than my own, _but_, it was explaining how to use the `template` option, the path to a `Vagrantfile` template, that you would base on the orginal one, here our `./packer/.base.box/content/Vagrantfile`.

And this post was showing a template which did include the way to insert the SSH key to use :

```Vagrant
Vagrant.configure(2) do |config|
  config.vm.define "source", autostart: false do |source|
    source.vm.box = "{{.SourceBox}}"
    config.ssh.insert_key = {{.InsertKey}}
  end

  config.vm.define "output" do |output|
    output.vm.box = "{{.BoxName}}"
    output.vm.box_url = "file://package.box"
    config.ssh.insert_key = {{.InsertKey}}
  end

  # These ‘provider’ definitions are not present in the original template.
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = `nproc`.to_i
  end

  config.vm.provider "vmware_desktop" do |v|
    v.vmx['memsize'] = 4096
    v.vmx['numvcpus'] = `nproc`.to_i
  end

  {{if ne .SyncedFolder "" -}}
    config.vm.synced_folder "{{.SyncedFolder}}", "/vagrant"
  {{- else -}}
    config.vm.synced_folder ".", "/vagrant", disabled: true
  {{- end}}
end
```

This template Vagrantfile drove me to <https://developer.hashicorp.com/vagrant/docs/vagrantfile/ssh_settings>, where I found my configuration option:

* For Vagrant, the `config.ssh.insert_key` configuration option is true by default
* Yet, the Packer Vagrant builder [sets `config.ssh.insert_key` to `false` by default](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant#optional):

![packer sets insert_key to false by defaults](./docs/images/packer.sets.config.vm.insert_key.to.false.PNG)

There we are, I should set `insert_key   = true`:

```bash

rm -fr ./golden/debian12

cat <<EOF >./packer.pkr.hcl
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
  source_path  = "./.base.box/debian12base.box"
  box_name     = "golden_debian12"
  output_dir   = "./golden/debian12"
  insert_key   = true
}

build {
  sources = ["source.vagrant.debian12_base"]

  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    script          = ".shell/.build/setup.sh"
  }

}
EOF

```

And I ran the packer build again... To find the same error.

I searched a bitmore, and added a template Vagrantfile, which content was exactly the same asthe base Vagrantfile, except I added a provider specific network interface config, plsu a section inspired by the above mentioned blog post, which gave me this Vagrantfile template:

```Vagrantfile

# The contents below were provided by the Packer Vagrant post-processor

Vagrant.configure("2") do |config|
  config.vm.base_mac = "0800276B552B"
end


# The contents below (if any) are custom contents provided by the
# Packer template during image build.
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # ---
  # config.ssh.private_key_path = ""
  # config.ssh.username = "vagrant" 
  # config.ssh.password = "vagrant"
  config.ssh.port     = 22
  
  config.vm.define "source", autostart: true do |source|
    source.vm.box = "{{.SourceBox}}"
    config.ssh.insert_key = {{.InsertKey}}
  end

  config.vm.define "output" do |output|
    output.vm.box = "{{.BoxName}}"
    # output.vm.box_url = "file://package.box"
    config.ssh.insert_key = {{.InsertKey}}
  end
  
  config.vm.boot_timeout = 1800
  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.box_check_update = true

  # config.vm.post_up_message = ""
  config.vm.boot_timeout = 1800
  # config.vm.box_download_checksum = true
  config.vm.boot_timeout = 1800
  # config.vm.box_download_checksum_type = "sha256"

  # config.vm.provision "shell", run: "always", inline: <<-SHELL
  # SHELL

  # Adding a second CPU and increasing the RAM to 2048MB will speed
  # things up considerably should you decide to do anythinc with this box.
  config.vm.provider :hyperv do |v, override|
    v.maxmemory = 2048
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provider :libvirt do |v, override|
    v.disk_bus = "virtio"
    v.driver = "kvm"
    v.video_vram = 256
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.provider :parallels do |v, override|
    v.customize ["set", :id, "--on-window-close", "keep-running"]
    v.customize ["set", :id, "--startup-view", "headless"]
    v.customize ["set", :id, "--memsize", "2048"]
    v.customize ["set", :id, "--cpus", "2"]
  end

  config.vm.provider :virtualbox do |v, override|
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--vram", 2048]
    v.customize ["modifyvm", :id, "--cpus", 4]
    v.customize ["modifyvm", :id, "--cable-connected1", "on"]
    v.customize ["modifyvm", :id, "--nic1", "bridged"]
    v.customize ["modifyvm", :id, "--bridge-adapter1", "TP-Link Wireless USB Adapter"]
    v.gui = true
  end

  ["vmware_fusion", "vmware_workstation", "vmware_desktop"].each do |provider|
    config.vm.provider provider do |v, override|
      v.whitelist_verified = true
      v.gui = false
      v.vmx["cpuid.coresPerSocket"] = "1"
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
    end
  end

end
```

That's where I understood something extremely important when working with `Packer`:

* I searched a bit and found very quickly how to change Packer's log level, changing it to debug: `export PACKER_LOG=debug`
* And as I ran again my Packerbuild,i finally found the error: `2024/03/01 22:34:39 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/01 22:34:39 [vagrant driver] stderr: The "metadata.json" file for the box './.base.box/debian12base.box' was not found.`.
* Absolutely nothing to do with any SSH configuration!
* soon i found a few related github issue on vagrant's github repository (I'm not alone in the world!):
  * this one is very interesting, its quite recent, and states the exact same issue as me (as I write this, March, 1st, 2024, and the issue dats bck to July 2022). Most Interesting also, the issuer tarballs the box for testing, using `tar -cvf`, while I used `tar -zcvf` instead : <https://github.com/hashicorp/vagrant/issues/12829>
  * even more interesting, there are **19** (!) closed issues which mention the `metadata.json` file: <https://github.com/hashicorp/vagrant/issues?q=is%3Aissue+The+%22metadata.json%22+file+for+the+box+%27custom%27+was+not+found+is%3Aclosed>

![vagrant issue - metadata.json - 19 times](./docs/images/vagrant_issue_19_times_raised.PNG)

* _**What I understood then**_: Packer works with plugins, this means that when a given plugin fails with an error, packer can only spito ut what the plugin passed him. So it is exetremely important to run packer with debug log level, to troubleshoot most of the difficulties experienced using a Packer builder.

Now, what I naturally did, to test if it was menot packaging well my tarball vagrant box:

* Instead of   `source_path  = "./.base.box/debian12base.box"`
* I used `source_path  = "https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box"`
* That, because my vagrant box was indeed coming from <https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box> , and it was the terraform provider who deflatedit, letting meplay with the following files on my local filesystem:

```bash
$ ls -alh ~/.terraform/virtualbox/gold/virtualbox/
total 1.2G
drwxr-xr-x 1 <My User> 197121    0 Feb 26 21:45 ./
drwxr-xr-x 1 <My User> 197121    0 Feb 26 21:45 ../
-rw-r--r-- 1 <My User> 197121 2.0K Jan 10 05:36 Vagrantfile
-rw-r--r-- 1 <My User> 197121 6.7K Jan 10 05:36 box.ovf
-rw-r--r-- 1 <My User> 197121 1.2G Feb 26 21:45 generic-debian12-virtualbox-x64-disk001.vmdk
-rw-r--r-- 1 <My User> 197121  301 Jan 10 05:36 info.json
-rw-r--r-- 1 <My User> 197121   49 Jan 10 05:36 metadata.json
```

No need to tell you that re-downloading the whole vagrant box is a very long test, and I will soon findout if the box is corrupted.

But I learned my lesson tonight. Next episode tomorrow.

Before going to sleep, as i finished writing my documentation, the Packer build based on the https URL of the debian 12 vagrant box, completed its execution, with an errorI already knowwhat it is about (I need to run the same packer build in powershell, not in git bash for windows, typical its like terraform, the golang binary searches for native widows file paths):

```bash
2024/03/01 23:43:31 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/01 23:43:31 [vagrant driver] stderr: C:/Program Files/Vagrant/embedded/mingw64/lib/ruby/3.1.0/fileutils.rb:243:in `mkdir': No such file or directory @ dir_s_mkdir - C:/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box (Errno::ENOENT)

```

Good night, with a little more documentation.

The next day, cosy afternoon, a good sleep the night before. I look again at the error I stopped work on yesterday, and an idea shows up:

* The error states that some file apparently does not exists, on my filesystem, the `C:/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box`
* So lets check that:

```bash

ls -alh /C/Users/Utilisateur/.vagrant.d/
ls -alh /C/Users/Utilisateur/.vagrant.d/boxes/
ls -alh /C/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box
```

Result:

```bash
$ ls -alh /C/Users/Utilisateur/.vagrant.d/
total 145K
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 23:43 ./
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 02:07 ../
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 23:23 boxes/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 23:43 data/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 gems/
-rw-r--r-- 1 Utilisateur 197121 1.7K Mar  1 20:15 insecure_private_key
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 insecure_private_keys/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 rgloader/
-rw-r--r-- 1 Utilisateur 197121    3 Mar  1 20:15 setup_version
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 23:43 tmp/

$ ls -alh /C/Users/Utilisateur/.vagrant.d/boxes/
total 4.0K
drwxr-xr-x 1 Utilisateur 197121 0 Mar  1 23:23 ./
drwxr-xr-x 1 Utilisateur 197121 0 Mar  1 23:43 ../
drwxr-xr-x 1 Utilisateur 197121 0 Mar  1 23:23 golden_debian12/

$ ls -alh /C/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box
ls: cannot access '/C/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box': No such file or directory

```

* Now Note that:
  * There is a folder that does exist, the `/C/Users/Utilisateur/.vagrant.d/boxes/golden_debian12/` folder.
  * And the error message is right, on my filesystem, there is no existing file or folder with path `/C/Users/Utilisateur/.vagrant.d/boxes/https-VAGRANTCOLON--VAGRANTSLASH--VAGRANTSLASH-app.vagrantup.com-VAGRANTSLASH-generic-VAGRANTSLASH-boxes-VAGRANTSLASH-debian12-VAGRANTSLASH-versions-VAGRANTSLASH-4.3.12-VAGRANTSLASH-providers-VAGRANTSLASH-virtualbox.box`
  * That, in my `packer.pkr.hcl` file, I gave to the :
    * `box_name` configuration property, the value `golden_debian12`.
    * `source_path` configuration property, the value `https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box`.
  * That on the [packer builder page](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant), the provided example, gives to the :
    * `source_path` configuration property, the value `hashicorp/precise64`.
    * That this `hashicorp/precise64` Vagrant box is available at <https://app.vagrantup.com/hashicorp/boxes/precise64>, and that the latest version of that box, for the virtualbox provider, can be downloaded with the URL [`https://app.vagrantup.com/hashicorp/boxes/precise64/versions/1.1.0/providers/virtualbox.box`](https://app.vagrantup.com/hashicorp/boxes/precise64/versions/1.1.0/providers/virtualbox.box)

  * So If I follow the same pattern asthe Packer vagrant builder, if i want my packer build to use the [`https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box`](https://app.vagrantup.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox.box), I should then :
    * set the `source_path` to `generic/debian12`
    * set the `box_name` to any name I never used before, to be able to make sure how `box_name` will be used (will i find a `${HOME}/.vagrant.d/boxes/<the new name I never used before>` ?)

I applied those changes in my packer build definition `./packer.pkr.hcl`, and to begin with, bingo, setting `source_path` to `generic/debian12`, resulted in downloading the expected box, see the output:

```bash
out:     box: Downloading: https://vagrantcloud.com/generic/boxes/debian12/versions/4.3.12/providers/virtualbox/amd64/vagrant.box
```

Bingo, the result is that I have a new error, which clearly states that i have an error in my `./packer/.vagrant/debian12/Vagrantfile.tpl` Vagrantfile template, about the video ram size, look (thank you packer logs again):

```bash
err: The following error was experienced:
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr:
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr: #<Vagrant::Errors::VBoxManageError: There was an error while executing `VBoxManage`, a CLI used by Vagrant
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr: for controlling VirtualBox. The command and stderr is shown below.
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr:
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr: Command: ["modifyvm", "7ad48baa-3040-491a-8655-7b0dd4c5e519", "--vram", "2048"]
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr:
2024/03/02 15:02:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:02:48 [vagrant driver] stderr: Stderr: VBoxManage.exe: error: Invalid VRAM size: 2048 MB (must be in range [0, 256] MB)

```

![firstbootup](./docs/images/finally_the_vm_gets_created_for_first_time.PNG)

Alright, so I will reset the video memory to the maximum value, 256.


And now we getto the famous problem about how toSSH into the booted VM:

```bash
out: ==> source: Waiting for machine to boot. This may take a few minutes...
2024/03/02 15:20:13 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:13 [vagrant driver] stdout:     source: SSH address: 127.0.0.1:22
2024/03/02 15:20:13 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:13 [vagrant driver] stdout:     source: SSH username: vagrant
2024/03/02 15:20:13 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:13 [vagrant driver] stdout:     source: SSH auth method: private key
2024/03/02 15:20:13 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:13 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
2024/03/02 15:20:24 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:24 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
2024/03/02 15:20:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:34 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
2024/03/02 15:20:44 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:44 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
2024/03/02 15:20:55 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:20:55 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
2024/03/02 15:21:05 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/02 15:21:05 [vagrant driver] stdout:     source: Warning: Authentication failure. Retrying...
```

My Packer build forever tries unsuccessfully to SSH into the VM.

I want to note a few things, before going to the next step:

* After I interrupted my almost-successful packer build, on my filesystem, I do have the answer to the question _will i find a `${HOME}/.vagrant.d/boxes/<the new name I never used before>` ?_: The answer is neither yes,nor no:
  * Yes: I have a `${HOME}/.vagrant.d/boxes/generic-VAGRANTSLASH-debian12/4.3.12/amd64/virtualbox/` Folder, containing the downloaded, unpacked, Vagrant box.
  * No: the name of the folder, containing the downloaded, unpacked, Vagrant box, created in the `${HOME}/.vagrant.d/boxes/` Vagrant folder, is not infered by the value we gave to the `box_name` configuration property. It is infered from the value of the `source_path`, `generic-VAGRANTSLASH-debian12` in our case.
* Moreover, worth noting as well, right after executing my packer build, I ran `vagrant box list -i`, which gives, foreach Vagrant box contained in the `${HOME}/.vagrant.d/boxes/` Vagrant folder, the all the informations contained in the `info.json`(and no other informations) :

```bash
$ vagrant box list -i
generic/debian12 (virtualbox, 4.3.12, (amd64))
  - Author: Ladar Levison
  - Website: https://roboxes.org/
  - Artifacts: https://vagrantcloud.com/generic/
  - Repository: https://github.com/lavabit/robox/
  - Description: Basic virtual machine images, for a variety of operating systems/hypervisors, and ready to serve as base bxoes.
golden_debian12  (virtualbox, 0)
  - Author: Ladar Levison
  - Website: https://roboxes.org/
  - Artifacts: https://vagrantcloud.com/generic/
  - Repository: https://github.com/lavabit/robox/
  - Description: Basic virtual machine images, for a variety of operating systems/hypervisors, and ready to serve as base bxoes.

```

* Finally, Remember, yesterday, after reading the results of my last test, beforegoing tosleep,I quickly added a few notes, including "_(I need to run the same packer build in powershell, not in git bash for windows, typical its like terraform, the golang binary searches for native widows file paths)_": I was jumping to a conclusion, before a careful, quiet analysis, with Johann Sebastian Bach in the background. I should have stated it as an idea for a possible explanation.

Okay, now that we made a few explicit fact gathering, let's rephrase our problem:

* I do have a Vagrant box, on which my packer build runs.
* The packer build tries to SSH into the booted VM:
  * using private key ssh authentication method
  * using `127.0.0.1` as host
  * using port `22` on the guest, and port `2222` on the host,indeed in the output we read `out:     source: 22 (guest) => 2222 (host) (adapter 1)`
  * using network adapter 1 of the VM

Obviously, the packer builder tries toSSH into the VM, expecting a NAT network adapter type, on the VirtualBox VM.

So now I will try this:

* I will change my `./packer/.vagrant/debian12/Vagrantfile.tpl` Vagrantfile template,
* So that :
  * the first network adapter uses NAT networking (instead of bridged)
  * the second network adapter will be a bridged one.

```Vagrantfile
  config.vm.provider :virtualbox do |v, override|
    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--vram", 256]
    v.customize ["modifyvm", :id, "--cpus", 4]
    # v.customize ["modifyvm", :id, "--cable-connected1", "on"]
    # v.customize ["modifyvm", :id, "--nic1", "bridged"]
    # v.customize ["modifyvm", :id, "--bridge-adapter1", "TP-Link Wireless USB Adapter"]
    v.customize ["modifyvm", :id, "--cable-connected1", "on"]
    v.customize ["modifyvm", :id, "--nic1", "nat"]
    # v.customize ["modifyvm", :id, "--bridge-adapter1", "TP-Link Wireless USB Adapter"]
    v.customize ["modifyvm", :id, "--cable-connected2", "on"]
    v.customize ["modifyvm", :id, "--nic2", "bridged"]
    v.customize ["modifyvm", :id, "--bridge-adapter2", "TP-Link Wireless USB Adapter"]
    v.gui = true
  end
```

Never the less, I don't expect the packer builder to successfully SSH into the VM: unless the vmdk disk does contain the ssh public key matching the ssh private key used by agrant, to ssh into the VM.

And indeed, the packer build failedagain to SSH into the VM:

* The packer builder does use the NAT network interface
* The VM does have a NAT interface,and the port forwarding isasexpected by the packer vagrant builder plugin: 22 inside the VM, 2222 outside (see screeshot below).

Now, I had a very good idea of a test: trying to manually SSH into the VM. That way I could verify:

* That If I try to SSH into the VM using the well-known vagrant user (`vagrant` as username / `vagrant` as password), through the NAT interface, it works! From there, into my machine:
  * I ran `sudo systemctl status sshd`: there I could check that the SSH server listens on all network interfaces (`0.0.0.0`), on port `22`.
  * I checked the content of several SSH configuratioon files: `/home/vagrant/.ssh/authorized_keys`, `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config`: There is indeed one SSH public key inside the `/home/vagrant/.ssh/authorized_keys` (so where do I get the SSH private key?), the usePAM option is active for the openssh-server
* But if I try the same, on the bridged network interface, it fails! As you can see in the below screenshot, well the reason was that the network interface did not get a DHCP IP address from my `TP Link Wireless Adapter` (I'll investigate later why, perhaps related to the mac address...)

```bash
$ ssh vagrant@127.0.0.1 -p2222
The authenticity of host '[127.0.0.1]:2222 ([127.0.0.1]:2222)' can't be established.
ED25519 key fingerprint is SHA256:Zus3rZZDbZqlZHO8tKQpg6mJY0/ooWpKLjL5YyRyniU.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[127.0.0.1]:2222' (ED25519) to the list of known hosts.
vagrant@127.0.0.1's password:
vagrant@debian12:~$ exit
logout
Connection to 127.0.0.1 closed.

```

The content of the `/home/vagrant/.ssh/authorized_keys`, `/etc/ssh/sshd_config`, `/etc/ssh/sshd_config` files, insidethe VM:

```bash
$ ssh vagrant@127.0.0.1 -p2222
vagrant@127.0.0.1's password:
Last login: Sat Mar  2 16:37:26 2024 from 10.0.2.2
vagrant@debian12:~$ sudo systemctl status sshd
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/lib/systemd/system/ssh.service; enabled; preset: enabled)
     Active: active (running) since Sat 2024-03-02 16:32:03 UTC; 16min ago
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 1321 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 1322 (sshd)
      Tasks: 1 (limit: 4644)
     Memory: 3.3M
        CPU: 156ms
     CGroup: /system.slice/ssh.service
             └─1322 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Mar 02 16:32:03 debian12.localdomain systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
Mar 02 16:32:03 debian12.localdomain sshd[1322]: Server listening on 0.0.0.0 port 22.
Mar 02 16:32:03 debian12.localdomain sshd[1322]: Server listening on :: port 22.
Mar 02 16:32:03 debian12.localdomain systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
Mar 02 16:37:25 debian12.localdomain sshd[1327]: Accepted password for vagrant from 10.0.2.2 port 8332 ssh2
Mar 02 16:37:25 debian12.localdomain sshd[1327]: pam_unix(sshd:session): session opened for user vagrant(uid=1000) by (uid=0)
Mar 02 16:37:26 debian12.localdomain sshd[1327]: pam_env(sshd:session): deprecated reading of user environment enabled
Mar 02 16:48:13 debian12.localdomain sshd[1369]: Accepted password for vagrant from 10.0.2.2 port 9736 ssh2
Mar 02 16:48:13 debian12.localdomain sshd[1369]: pam_unix(sshd:session): session opened for user vagrant(uid=1000) by (uid=0)
Mar 02 16:48:14 debian12.localdomain sshd[1369]: pam_env(sshd:session): deprecated reading of user environment enabled
vagrant@debian12:~$ cat /etc/ssh/sshd_config

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/local/bin:/usr/bin:/bin:/usr/games

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile     .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
KbdInteractiveAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the KbdInteractiveAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via KbdInteractiveAuthentication may bypass
PermitRootLogin yes
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and KbdInteractiveAuthentication to 'no'.
UsePAM yes

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
#TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem       sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#       X11Forwarding no
#       AllowTcpForwarding no
#       PermitTTY no
#       ForceCommand cvs server
vagrant@debian12:~$ cat /home/vagrant/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
vagrant@debian12:~$ cat /etc/ssh/
moduli                    ssh_config.d/             sshd_config.d/            ssh_host_ecdsa_key.pub    ssh_host_ed25519_key.pub  ssh_host_rsa_key.pub
ssh_config                sshd_config               ssh_host_ecdsa_key        ssh_host_ed25519_key      ssh_host_rsa_key
vagrant@debian12:~$ cat /etc/ssh/ssh_
ssh_config                ssh_host_ecdsa_key        ssh_host_ed25519_key      ssh_host_rsa_key
ssh_config.d/             ssh_host_ecdsa_key.pub    ssh_host_ed25519_key.pub  ssh_host_rsa_key.pub
vagrant@debian12:~$ ls -alh /etc/ssh/ssh_config.d/
total 8.0K
drwxr-xr-x 2 root root 4.0K Dec 19 14:51 .
drwxr-xr-x 4 root root 4.0K Mar  2 16:32 ..
vagrant@debian12:~$ cat /etc/ssh/ssh_config

# This is the ssh client system-wide configuration file.  See
# ssh_config(5) for more information.  This file provides defaults for
# users, and the values can be changed in per-user configuration files
# or on the command line.

# Configuration data is parsed as follows:
#  1. command line options
#  2. user-specific file
#  3. system-wide file
# Any configuration value is only changed the first time it is set.
# Thus, host-specific definitions should be at the beginning of the
# configuration file, and defaults at the end.

# Site-wide defaults for some commonly used options.  For a comprehensive
# list of available options, their meanings and defaults, please see the
# ssh_config(5) man page.

Include /etc/ssh/ssh_config.d/*.conf

Host *
#   ForwardAgent no
#   ForwardX11 no
#   ForwardX11Trusted yes
#   PasswordAuthentication yes
#   HostbasedAuthentication no
#   GSSAPIAuthentication no
#   GSSAPIDelegateCredentials no
#   GSSAPIKeyExchange no
#   GSSAPITrustDNS no
#   BatchMode no
#   CheckHostIP yes
#   AddressFamily any
#   ConnectTimeout 0
#   StrictHostKeyChecking ask
#   IdentityFile ~/.ssh/id_rsa
#   IdentityFile ~/.ssh/id_dsa
#   IdentityFile ~/.ssh/id_ecdsa
#   IdentityFile ~/.ssh/id_ed25519
#   Port 22
#   Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-cbc,3des-cbc
#   MACs hmac-md5,hmac-sha1,umac-64@openssh.com
#   EscapeChar ~
#   Tunnel no
#   TunnelDevice any:any
#   PermitLocalCommand no
#   VisualHostKey no
#   ProxyCommand ssh -q -W %h:%p gateway.example.com
#   RekeyLimit 1G 1h
#   UserKnownHostsFile ~/.ssh/known_hosts.d/%k
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes
vagrant@debian12:~$ exit
logout
Connection to 127.0.0.1 closed.

```

In other words, the VM has an SSH config, inside the VM, which allows SSH from users, using password, only though the 127.0.0.1 network host. And it makes so much sense in terms of the philosophy, of the PXEless boot!

Indeed, this means you can only locally work on the machine, that really is, pixieless-booting! Build it locally, deploy it and go!

Now, let'sgo back asecond ont the question: But where is the private key? We don't have to look for it very long, look:

```bash
$ ls -alh ~/.vagrant.d/
total 145K
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 17:28 ./
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 17:20 ../
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 14:59 boxes/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 17:31 data/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 gems/
-rw-r--r-- 1 Utilisateur 197121 1.7K Mar  1 20:15 insecure_private_key
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 insecure_private_keys/
drwxr-xr-x 1 Utilisateur 197121    0 Mar  1 20:15 rgloader/
-rw-r--r-- 1 Utilisateur 197121    3 Mar  1 20:15 setup_version
drwxr-xr-x 1 Utilisateur 197121    0 Mar  2 17:28 tmp/

$ ls -alh ~/.vagrant.d/insecure_private_key
-rw-r--r-- 1 Utilisateur 197121 1.7K Mar  1 20:15 /c/Users/Utilisateur/.vagrant.d/insecure_private_key

$ ssh -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1 -p2222
Last login: Sat Mar  2 16:54:30 2024
vagrant@debian12:~$ Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.

```

So now I add `ssh_private_key_file = "~/.vagrant.d/insecure_private_key"` to my `packer.pkr.hcl`,and I start the build again.

For the moment, I still get a failure to connect through ssh: there I knew I had left in my `./packer/.vagrant/debian12/Vagrantfile.tpl` Vagrantfile template, a configuration line regarding ssh, `config.ssh.port     = 22`,which I commented.

Also, I used the below command, so that the ssh connection does not require to trust the openssh server interactively :

```bash
ssh-keyscan -p 2222 -H 127.0.0.1 >> ~/.ssh/known_hosts
```

Yet, every time I launch the packer build, I would have to delete the `~/.ssh/known_hosts` file, and run ssh-keyscan again... No I found in this [blog post](https://kentrichards.net/blog/bypass-knownhosts-file-vagrant-boxes) a good idea to solve this issue:

```bash
cat <<EOF >./addon.to.ssh.config
######################################################
# Vagrant
######################################################

Host 192.168.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host 127.0.0.1
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host local.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

Host *.loc
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF

cat ./addon.to.ssh.config | tee -a ~/.ssh/config
```

and there I got a new failure, but with different, encouragingnew output messages, look:

```bash
out: Progress: 70%
2024/03/03 01:28:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:34 [vagrant driver] stdout: ==> source: Matching MAC address for NAT networking...
2024/03/03 01:28:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:34 [vagrant driver] stdout: ==> source: Checking if box 'generic/debian12' version '4.3.12' is up to date...
2024/03/03 01:28:37 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:37 [vagrant driver] stdout: ==> source: Setting the name of the VM: debian12_remote_source_1709425717237_78424
2024/03/03 01:28:37 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:37 [vagrant driver] stdout: ==> source: Clearing any previously set network interfaces...
2024/03/03 01:28:38 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:38 [vagrant driver] stdout: ==> source: Preparing network interfaces based on configuration...
2024/03/03 01:28:38 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:38 [vagrant driver] stdout:     source: Adapter 1: nat
2024/03/03 01:28:38 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:38 [vagrant driver] stdout: ==> source: Forwarding ports...
2024/03/03 01:28:38 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:38 [vagrant driver] stdout:     source: 22 (guest) => 2222 (host) (adapter 1)
2024/03/03 01:28:38 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:38 [vagrant driver] stdout: ==> source: Running 'pre-boot' VM customizations...
2024/03/03 01:28:39 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:39 [vagrant driver] stdout: ==> source: Booting VM...
2024/03/03 01:28:49 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:49 [vagrant driver] stdout: ==> source: Waiting for machine to boot. This may take a few minutes...
2024/03/03 01:28:50 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:50 [vagrant driver] stdout:     source: SSH address: 127.0.0.1:2222
2024/03/03 01:28:50 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:50 [vagrant driver] stdout:     source: SSH username: vagrant
2024/03/03 01:28:50 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:28:50 [vagrant driver] stdout:     source: SSH auth method: private key
2024/03/03 01:29:22 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:22 [vagrant driver] stdout:     source:
2024/03/03 01:29:22 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:22 [vagrant driver] stdout:     source: Vagrant insecure key detected. Vagrant will automatically replace
2024/03/03 01:29:22 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:22 [vagrant driver] stdout:     source: this with a newly generated keypair for better security.
2024/03/03 01:29:25 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:25 [vagrant driver] stdout:     source:
2024/03/03 01:29:25 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:25 [vagrant driver] stdout:     source: Inserting generated public key within guest...
2024/03/03 01:29:26 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:26 [vagrant driver] stdout:     source: Removing insecure key from the guest if it's present...
2024/03/03 01:29:26 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:26 [vagrant driver] stdout:     source: Key inserted! Disconnecting and reconnecting using new SSH key...
2024/03/03 01:29:27 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:27 [vagrant driver] stdout: ==> source: Machine booted and ready!
2024/03/03 01:29:28 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:28 [vagrant driver] stdout: ==> source: Checking for guest additions in VM...
2024/03/03 01:29:28 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:28 Calling Vagrant CLI: []string{"ssh-config", "source"}
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout: Host source
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   HostName 127.0.0.1
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   User vagrant
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   Port 2222
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   UserKnownHostsFile /dev/null
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   StrictHostKeyChecking no
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   PasswordAuthentication no
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   IdentityFile C:/Users/Utilisateur/packman/packer/golden/debian12_remote/.vagrant/machines/source/virtualbox/private_key
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   IdentitiesOnly yes
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   LogLevel FATAL
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   PubkeyAcceptedKeyTypes +ssh-rsa
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:   HostKeyAlgorithms +ssh-rsa
2024/03/03 01:29:33 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:33 [vagrant driver] stdout:
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 Overriding SSH config from Vagrant with the username, password, and private key information provided to the Packer template.
==> vagrant.debian12_base: Using SSH communicator to connect: 127.0.0.1
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [INFO] Waiting for SSH, up to timeout: 10m0s
==> vagrant.debian12_base: Waiting for SSH to become available...
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [INFO] Attempting SSH connection to 127.0.0.1:2222...
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [DEBUG] reconnecting to TCP connection for SSH
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [DEBUG] handshaking with SSH
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [DEBUG] SSH handshake err: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
2024/03/03 01:29:34 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:34 [DEBUG] Detected authentication error. Increasing handshake attempts.
2024/03/03 01:29:41 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:41 [INFO] Attempting SSH connection to 127.0.0.1:2222...
2024/03/03 01:29:41 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:41 [DEBUG] reconnecting to TCP connection for SSH
2024/03/03 01:29:41 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:41 [DEBUG] handshaking with SSH
2024/03/03 01:29:41 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:41 [DEBUG] SSH handshake err: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
2024/03/03 01:29:41 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:41 [DEBUG] Detected authentication error. Increasing handshake attempts.
2024/03/03 01:29:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:48 [INFO] Attempting SSH connection to 127.0.0.1:2222...
2024/03/03 01:29:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:48 [DEBUG] reconnecting to TCP connection for SSH
2024/03/03 01:29:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:48 [DEBUG] handshaking with SSH
2024/03/03 01:29:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:48 [DEBUG] SSH handshake err: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain
2024/03/03 01:29:48 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:48 [DEBUG] Detected authentication error. Increasing handshake attempts.
2024/03/03 01:29:55 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:55 [INFO] Attempting SSH connection to 127.0.0.1:2222...
2024/03/03 01:29:55 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:55 [DEBUG] reconnecting to TCP connection for SSH
2024/03/03 01:29:55 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:55 [DEBUG] handshaking with SSH
2024/03/03 01:29:55 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 01:29:55 [DEBUG] SSH handshake err: ssh: handshake failed: ssh: unable to authenticate, attempted methods [none publickey], no supported methods remain

```

Let's clean a bit, a few lines before thefirst SSH authentication failures start. To do the clean up,I belowremoved all datetime stamps, and the `packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin:` string appearingon each line:

```bash
[vagrant driver] stdout:     source: Adapter 1: nat
[vagrant driver] stdout: ==> source: Forwarding ports...
[vagrant driver] stdout:     source: 22 (guest) => 2222 (host) (adapter 1)
[vagrant driver] stdout: ==> source: Running 'pre-boot' VM customizations...
[vagrant driver] stdout: ==> source: Booting VM...
[vagrant driver] stdout: ==> source: Waiting for machine to boot. This may take a few minutes...
[vagrant driver] stdout:     source: SSH address: 127.0.0.1:2222
[vagrant driver] stdout:     source: SSH username: vagrant
[vagrant driver] stdout:     source: SSH auth method: private key
[vagrant driver] stdout:     source:
[vagrant driver] stdout:     source: Vagrant insecure key detected. Vagrant will automatically replace
[vagrant driver] stdout:     source: this with a newly generated keypair for better security.
[vagrant driver] stdout:     source:
[vagrant driver] stdout:     source: Inserting generated public key within guest...
[vagrant driver] stdout:     source: Removing insecure key from the guest if it's present...
[vagrant driver] stdout:     source: Key inserted! Disconnecting and reconnecting using new SSH key...
[vagrant driver] stdout: ==> source: Machine booted and ready!
[vagrant driver] stdout: ==> source: Checking for guest additions in VM...
Calling Vagrant CLI: []string{"ssh-config", "source"}
[vagrant driver] stdout: Host source
[vagrant driver] stdout:   HostName 127.0.0.1
[vagrant driver] stdout:   User vagrant
[vagrant driver] stdout:   Port 2222
[vagrant driver] stdout:   UserKnownHostsFile /dev/null
[vagrant driver] stdout:   StrictHostKeyChecking no
[vagrant driver] stdout:   PasswordAuthentication no
[vagrant driver] stdout:   IdentityFile C:/Users/Utilisateur/packman/packer/golden/debian12_remote/.vagrant/machines/source/virtualbox/private_key
[vagrant driver] stdout:   IdentitiesOnly yes
[vagrant driver] stdout:   LogLevel FATAL
[vagrant driver] stdout:   PubkeyAcceptedKeyTypes +ssh-rsa
[vagrant driver] stdout:   HostKeyAlgorithms +ssh-rsa
[vagrant driver] stdout:
Overriding SSH config from Vagrant with the username, password, and private key information provided to the Packer template.
==> vagrant.debian12_base: Using SSH communicator to connect: 127.0.0.1
[INFO] Waiting for SSH, up to timeout: 10m0s
==> vagrant.debian12_base: Waiting for SSH to become available...
[INFO] Attempting SSH connection to 127.0.0.1:2222...
```

And that's where I understood, what was the last thing that was wrong in my configuration:

* my packer build has `insert_key = true`, and the above logs are very clear about what it does: 
  * the packer vagrant builder generates a new SSH Key pair, inserts the public key inside my VM, removes the well-known insecure Vagrant key
  * logs out, and tries to SSH again into the VM,
  * but instead of using the new private key, it tries using theprivate key I specified with the `ssh_private_key_path` configuration property, which points at the insecurewellknown Vagrant private key.
  * So all in all, to solve my issue:
    * either I set `insert_key = false`
    * Or do not use the `ssh_private_key_path` configuration property.

I then tried setting `insert_key = false` and **TADAAAAAA** finalllyyyyy my packerbuild completes without error,and I get a well created, brand new Vagrant Box in the `golden/debian12_remote` folder which path i set with the `output_dir` configuration property:

```bash
==> vagrant.debian12_base: destroying Vagrant box...
2024/03/03 02:03:37 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 02:03:37 Calling Vagrant CLI: []string{"destroy", "-f", "source"}
2024/03/03 02:03:46 packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe plugin: 2024/03/03 02:03:46 [vagrant driver] stdout: ==> source: Destroying VM and associated drives...
2024/03/03 02:03:47 [INFO] (telemetry) ending vagrant.debian12_base
==> Wait completed after 7 minutes 33 seconds
Build 'vagrant.debian12_base' finished after 7 minutes 33 seconds.

==> Builds finished. The artifacts of successful builds are:
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact-count []string{"1"}
==> Wait completed after 7 minutes 33 seconds

==> Builds finished. The artifacts of successful builds are:
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "builder-id", "vagrant"}
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "id", "virtualbox"}
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "string", "Vagrant box 'package.box' for 'virtualbox' provider"}
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "files-count", "1"}
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "file", "0", "golden\\debian12_remote\\package.box"}
2024/03/03 02:03:47 machine readable: vagrant.debian12_base,artifact []string{"0", "end"}
2024/03/03 02:03:47 [INFO] (telemetry) Finalizing.
--> vagrant.debian12_base: Vagrant box 'package.box' for 'virtualbox' provider
2024/03/03 02:03:48 waiting for all plugin processes to complete...
2024/03/03 02:03:48 [ERR] yamux: Failed to read header: read tcp 127.0.0.1:23596->127.0.0.1:10000: wsarecv: Une connexion existante a dû être fermée par l’hôte distant.
2024/03/03 02:03:48 [ERR] yamux: Failed to read header: read tcp 127.0.0.1:23597->127.0.0.1:10000: wsarecv: Une connexion existante a dû être fermée par l’hôte distant.
2024/03/03 02:03:48 C:\Users\Utilisateur\AppData\Roaming\packer.d\plugins\github.com\hashicorp\vagrant\packer-plugin-vagrant_v1.1.2_x5.0_windows_amd64.exe: plugin process exited
2024/03/03 02:03:48 C:\ProgramData\chocolatey\lib\packer\tools\packer.exe: plugin process exited

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer (feature/set/ssh/key)
$ echo "$?"
0

```

I can with the newly created vagrant box, run vagrant up:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer/golden/debian12_remote (feature/set/ssh/key)
$ vagrant up --provider virtualbox
Bringing machine 'source' up with 'virtualbox' provider...
Bringing machine 'output' up with 'virtualbox' provider...
==> source: Importing base box 'generic/debian12'...
==> source: Matching MAC address for NAT networking...
==> source: Checking if box 'generic/debian12' version '4.3.12' is up to date...
==> source: Setting the name of the VM: debian12_remote_source_1709428629334_56917
==> source: Clearing any previously set network interfaces...
==> source: Preparing network interfaces based on configuration...
    source: Adapter 1: nat
==> source: Forwarding ports...
    source: 22 (guest) => 2222 (host) (adapter 1)
==> source: Running 'pre-boot' VM customizations...
==> source: Booting VM...
==> source: Waiting for machine to boot. This may take a few minutes...
    source: SSH address: 127.0.0.1:2222
    source: SSH username: vagrant
    source: SSH auth method: private key
==> source: Machine booted and ready!
==> source: Checking for guest additions in VM...
==> output: Box 'golden_debian12_remote' could not be found. Attempting to find and install...
    output: Box Provider: virtualbox
    output: Box Version: >= 0
==> output: Box file was not detected as metadata. Adding it directly...
==> output: Adding box 'golden_debian12_remote' (v0) for provider: virtualbox
    output: Downloading: golden_debian12_remote
    output:
An error occurred while downloading the remote file. The error
message, if any, is reproduced below. Please fix this error and try
again.

Couldn't open file C:/Users/Utilisateur/packman/packer/golden/debian12_remote/golden_debian12_remote

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer/golden/debian12_remote (feature/set/ssh/key)
$ ls -alh .
total 1.2G
drwxr-xr-x 1 Utilisateur 197121    0 Mar  3 02:02 ./
drwxr-xr-x 1 Utilisateur 197121    0 Mar  3 01:56 ../
drwxr-xr-x 1 Utilisateur 197121    0 Mar  3 01:56 .vagrant/
-rw-r--r-- 1 Utilisateur 197121 3.1K Mar  3 01:56 Vagrantfile
-rw-r--r-- 1 Utilisateur 197121 1.2G Mar  3 02:03 package.box

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer/golden/debian12_remote (feature/set/ssh/key)
$ tree -alh .vagrant/
.vagrant/
|-- [   0]  machines
|   |-- [   0]  output
|   |   `-- [   0]  virtualbox
|   |       `-- [  58]  vagrant_cwd
|   `-- [   0]  source
|       `-- [   0]  virtualbox
|           |-- [  40]  action_provision
|           |-- [  10]  action_set_name
|           |-- [ 144]  box_meta
|           |-- [   1]  creator_uid
|           |-- [  36]  id
|           |-- [  32]  index_uuid
|           |-- [   2]  synced_folders
|           `-- [  58]  vagrant_cwd
`-- [   0]  rgloader
    `-- [ 423]  loader.rb

6 directories, 10 files

Utilisateur@Utilisateur-PC MINGW64 ~/packman/packer/golden/debian12_remote (feature/set/ssh/key)
$ tree -alh .
.
|-- [   0]  .vagrant
|   |-- [   0]  machines
|   |   |-- [   0]  output
|   |   |   `-- [   0]  virtualbox
|   |   |       `-- [  58]  vagrant_cwd
|   |   `-- [   0]  source
|   |       `-- [   0]  virtualbox
|   |           |-- [  40]  action_provision
|   |           |-- [  10]  action_set_name
|   |           |-- [ 144]  box_meta
|   |           |-- [   1]  creator_uid
|   |           |-- [  36]  id
|   |           |-- [  32]  index_uuid
|   |           |-- [   2]  synced_folders
|   |           `-- [  58]  vagrant_cwd
|   `-- [   0]  rgloader
|       `-- [ 423]  loader.rb
|-- [3.0K]  Vagrantfile
`-- [1.1G]  package.box

7 directories, 12 files

```

To stopmy VM, I just have to run `vagrant halt`
To destroy my created VM, I just have to run `vagrant destroy -f`.

If I instead, decided to set `insert_key = true`, and commenting my `ssh_private_key_path` configuration property, I would findthe new securely generated SSH private key inside the `output_dir`. And indeed, that would be more secure, and its handy, let's admit it.

Here I am with with my first successful packer build, with the packer vagrant builder plugin.

Now I just noticed one issue, and that's my next step:
* my `script          = ".shell/.build/setup.sh"` shell script does execute in the VM during the build, and among others, it installs `jq`.
* But when I vagrant up my new Vagrant box, I don't find any `jq`.

So this is about understanding bettermy shell provisioner.

Ok I think I found why I have this strange behavior:
* [perhaps its like this issue](https://github.com/hashicorp/packer/issues/4182#issuecomment-261570851)
* Ohhhh uncommenting in the Vagrantfile template, the `# output.vm.box_url = "file://package.box"` might help there... see also https://github.com/hashicorp/vagrant/issues/13009
* ok i'll search that tomorrow...
* Ok i couldn't help trying and yes it was that i had to un comment the `output.vm.box_url = "file://package.box"` line in my Vagrantfile template and its now all good :D , `jq` is indeed found in the `vagrant up`-spawned VM, together with all installed packages thats great.

Next steps:

* adding new disks to my VM (and mount them automatically)
* customize `/etc/network/interfaces` and `/etc/network/interfaces.d/*` netork configurations
* bring an actual, clean golden images pipeline: I need a clear schematics of a full lifecycle management case, for PXEless designed images (immutable infrrastructure). I need there to raise the conept of VM appliances, VM being instances of those appliances.
<!--
* I want to be able to build my own Vagrant applicance for VMware instead of Virtualbox: tere exaccctlyy what i need to demoimmutable updates/upgrades : https://developer.hashicorp.com/terraform/tutorials/virtual-machine/vsphere-provider
-->
* I want to get rid of vagrant: to go from Vagrant boxes, to OVF appliances with virtualbox-ovf builder,
* I want another appliances pipeline with virutalbox-iso/virtualbox-ovf/virtualbox-ovf https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox

Something else I want to have a look on later (how to package a VirtualBox VM into a Vagrant Box):

```bash
$ vagrant package --help
Usage: vagrant package [options] [name|id]

Options:

        --base NAME                  Name of a VM in VirtualBox to package as a base box (VirtualBox Only)
        --output NAME                Name of the file to output
        --include FILE,FILE..        Comma separated additional files to package with the box
        --info FILE                  Path to a custom info.json file containing additional box information
        --vagrantfile FILE           Vagrantfile to package with the box
        --[no-]color                 Enable or disable color output
        --machine-readable           Enable machine readable output
    -v, --version                    Display Vagrant version
        --debug                      Enable debug output
        --timestamp                  Enable timestamps on log output
        --debug-timestamp            Enable debug output with timestamps
        --no-tty                     Enable non-interactive output
    -h, --help                       Print this help

```

I note today, one last thing:

In my `./packer/.vagrant/debian12/Vagrantfile.tpl` Vagrantfile template, I had an `autostart` option set to `true`, so that when I `vagrant up --provider virtualbox` my Virtual Machine, I had the surprise to see not one, but twovirtual machines: According the Vagrant terminology, the _"source"_, and the _"output"_.

I set that `autostart` option to `false`, and then only my expected Virtualbox VM was 

## ANNEX: troubleshooting commands

Other commands I used to analyze what is going on:

* on the windows host, running Virtual Box, in Git bash for windows:

```bash
netstat -anob | grep 2222
```

This once gave me :

```bash
$ netstat -anob | grep 2222
  TCP    127.0.0.1:2222         0.0.0.0:0              LISTENING       13872
  TCP    127.0.0.1:23135        127.0.0.1:2222         TIME_WAIT       0
```

* In the VM, I used `sudo systemctl status sshd`, to check for logs to say if there was a successful established connection,

## ANNEX: Interesting Github issues

* https://github.com/hashicorp/packer/issues/7758

## ANNEX: Packer misc

* How to convert a packer `json` configuration file, to a packer `hcl` configuration file:

```bash
packer hcl2_upgrade -output-file=packer.pkr.hcl packer.pkr.json
```

## ANNEX: References

* The Packer Vagrant Builder: <https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant>.
* **The Packer virtualbox builders, there are 3 of them which are all interesting. Those 3 can be a good base to design a "pipeline", for provisioning golden images. I am particularly interested in the virtualbox-iso one which I would like to use to build a debian Virtual box VM from an iso file, and a debian preseed, the pressed should contain the post install script, and in the post install script we would install the public SSH KEy into the `~/.ssh/authorized_keys`. <https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox>**
* A tutorial on the packer vagrant builder: <https://dev.to/mattdark/a-custom-vagrant-box-with-packer-13ke>
* Other packer tutorials:

  * <https://medium.com/notes-and-tips-in-full-stack-development/how-to-automate-building-local-virtual-machines-with-packer-a238ba6b49c7>
  * `qemu` :
    * <https://github.com/miry/samples/tree/master/experiments/3-packer-images/>
    * Install `qemu` on windows : <https://www.qemu.org/download/#windows>
  * debian preseeds:
    * <https://gist.github.com/slattery/fc7cf2efc395086544c0>
    * <https://www.debian.org/releases/buster/amd64/apbs02.en.html>
