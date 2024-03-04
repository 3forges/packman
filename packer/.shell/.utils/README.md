# What's this?

The `prepare.sh` script:

* generates an SSH key pair
* generates the `./.shell/.build/setup.sh` script,
* the `./.shell/.build/setup.sh` script will be the shell script executed in the VM by packer with the shell provisioner. Basically, it plays the role of a post install script in a `preseed` configuration, responsible of:
  * Installing `openssh-server` package
  * creating the linux user I will use to ssh into the VM when I use it
  * adding the public SSH key into the `${HOME}/.ssh/authorized_keys`, for that linux user.
  * configuring `/etc/ssh/sshd_config` with `usePAM` authentication, and forbidding any password-based authentication.
  * configures the `/etc/fstab` to permanently mount partitions of each disk, on the filesystem:
    * two disks (2 VMDKs), each `ext4` formatted into one single partition, one is 20GB, the other 40GB,
    * the 20GB mounted on `/`
    * the 40GB mounted on `/var/lib/docker/overlay`
    * I'll have to figure out both of the partitions UUIDs to append the `/etc/fstab`with proper configs
  * removes the vagrant user's /etc/sudoers configuration
  * deletes the vagrant and root users, before exiting the ssh shell session opened by Packer through the vagrant builder, at build time.
* finally, it builds again the Vagrant box file `./.base.box/debian12base.box`, using `tar -zcvf` (or `tar -cvf`), from the files found in `./.base.box/content/`