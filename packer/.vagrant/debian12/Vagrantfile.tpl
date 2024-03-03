
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
  # config.ssh.port     = 22
  
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