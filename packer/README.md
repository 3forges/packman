# The Packer part

In the analysis of the terraform provider to provision our debian VM, we ended up with a fully functional debian VM, nevertheless lacking an SSH KEy inside.

Our terraform recipe:
* downloads a vagrant box, from the vagrant boxes registry, in the `ccc` folder.
* 

The purpose of this recipe, is:
* to build, using packer, a new vagrant box, relying on an already existing one in the local filesystem
* the new vagrant box will give a VirutlaBox VM : 
  * with an SSH Key inside
  * with Docker, and Docker compose installed
  * with,if possible, two virtual disks, instead of just one: both dynamically allocated, one is 20GB, the second 40GB for the docker `data-root`

To achieve our goal, we will use Packer's [vagrant](https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant) builder. That builder we are very interested in, because of two perfect properties for our case:

* we preferable do not want to install vagrant: unforutnaltely, the vagrant packer builder does require to install vagrant.
* we would like to just modify an eisting Vagrant Box.

## (Re)-Install Packer

TODO

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


## ANNEX: Interesting Github issues

* https://github.com/hashicorp/packer/issues/7758

## ANNEX: Packer misc

* How to convert a packer `json` configuration file, to a packer `hcl` configuration file:

```bash
packer hcl2_upgrade -output-file=packer.hcl packer.json
```

## ANNEX: References

* The Packer Vagrant Builder: <https://developer.hashicorp.com/packer/integrations/hashicorp/vagrant/latest/components/builder/vagrant>.
* **The Packer virtualbox builders, there are 3 of them which are al interesting. Those 3 can be a good base to design a "pipeline", for provisioning golden images. I am particularly interested in the virtualbox-iso one which I would like to use to build a debian Virtual box VM from an iso file, and a debian preseed, the pressed should contain the post install script, and in the post install script we would install the public SSH KEy into the `~/.ssh/authorized_keys`. <https://developer.hashicorp.com/packer/integrations/hashicorp/virtualbox>**
* A tutorial on the packer vagrant builder: <https://dev.to/mattdark/a-custom-vagrant-box-with-packer-13ke>
* Other packer tutorials:

  * <https://medium.com/notes-and-tips-in-full-stack-development/how-to-automate-building-local-virtual-machines-with-packer-a238ba6b49c7>
  * `qemu` : 
    * https://github.com/miry/samples/tree/master/experiments/3-packer-images/
    * Install `qemu` on windows : https://www.qemu.org/download/#windows
  * debian preseeds:
    * https://gist.github.com/slattery/fc7cf2efc395086544c0
    * https://www.debian.org/releases/buster/amd64/apbs02.en.html
