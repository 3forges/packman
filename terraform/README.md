# The Terraform part

The work in this folder:
* proves that the [terra-faram/virtualbox](https://github.com/terra-farm/terraform-provider-virtualbox) terraform provider simply does not work, on Git bash for windows, if it ever worked at all.
* It also is a base to analyze the design of that provider, and find improvements, for a complete new implementation of a terraform provider making it possible to fully manage virtualbox-based virtual machines.

This work also was the opportunity to definitely prove how to use the `dev_orverrides` terraform configuration, with today's recent versions of terraform.

That, as a preambule work for completely re-imlementing a virtualbox cloud provider and its associated terraform provider.

## Stack versions

* Git bash:

```bash
Utilisateur@Utilisateur-PC MINGW64 ~/packman (feature/first/implementation)
$ terraform version
Terraform v1.3.0
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.7.4. You can update by downloading from https://www.terraform.io/downloads.html

Utilisateur@Utilisateur-PC MINGW64 ~/packman (feature/first/implementation)
$ go version
go version go1.18.3 windows/amd64

Utilisateur@Utilisateur-PC MINGW64 ~/packman (feature/first/implementation)
$ VBoxManage --version
7.0.6r155176
```

* Powershell:

```Powershell
Windows PowerShell
Copyright (C) Microsoft Corporation. Tous droits réservés.

Testez le nouveau système multiplateforme PowerShell https://aka.ms/pscore6

PS C:\Users\Utilisateur> $Env:Path += ';C:\jibl_vbox\install'
PS C:\Users\Utilisateur> terraform version
Terraform v1.3.0
on windows_amd64

Your version of Terraform is out of date! The latest version
is 1.7.4. You can update by downloading from https://www.terraform.io/downloads.html
PS C:\Users\Utilisateur> go version
go version go1.18.3 windows/amd64
PS C:\Users\Utilisateur> VBoxManage --version
7.0.6r155176
PS C:\Users\Utilisateur>
```

## How to run

### Git bash for windows

* Locally Install the provider : 

```bash
# ~/.terraform.d/plugins/terraform.local/local/zabbix/1.0.0/linux_amd64/terraform-provider-zabbix_v1.0.0

export TF_PROVIDER_DESIRED_VERSION="0.2.2-alpha.1"

mkdir -p ./.terraform.d/customised-providers/terraform-provider-virtualbox/${TF_PROVIDER_DESIRED_VERSION}/

git clone git@github.com:terra-farm/terraform-provider-virtualbox.git ./.terraform.d/customised-providers/terraform-provider-virtualbox/${TF_PROVIDER_DESIRED_VERSION}/

cd ./.terraform.d/customised-providers/terraform-provider-virtualbox/${TF_PROVIDER_DESIRED_VERSION}/

git checkout "v${TF_PROVIDER_DESIRED_VERSION}"
rm -fr ./.git/

go build -o terraform-provider-virtualbox_v${TF_PROVIDER_DESIRED_VERSION}

mkdir -p ../bidule/

cp terraform-provider-virtualbox_v${TF_PROVIDER_DESIRED_VERSION} ../bidule/
rm terraform-provider-virtualbox_v${TF_PROVIDER_DESIRED_VERSION}


cd ../../../../


```

* Run:

```bash

export TF_CLI_CONFIG_FILE=$(pwd)/.dev.tfrc

export TF_LOG=debug

terraform validate
terraform fmt

terraform plan -out=my.first.plan.tfplan
terraform apply -auto-approve "my.first.plan.tfplan"


```

### Powershell

```Powershell
# ---
#  Note that on my machine, the [VBoxManage.exe] executable
#  file is located in 
#  the "C:\jibl_vbox\install" folder, where 
#  I installed VirtualBox. 
$Env:Path += ';C:\jibl_vbox\install'

$Env:TF_CLI_CONFIG_FILE = "./.dev.tfrc"
$Env:TF_LOG = "debug"

terraform validate
terraform fmt

terraform plan -out=my.first.powershell.plan.tfplan
terraform apply -auto-approve "my.first.powershell.plan.tfplan"

```

## Results

We have tested the latest release of the terrafarm virtualbox provider, the `0.2.2-alpha.1` release, both in Git bash for windows, and powershell, with a full build from source of the terraform provider.


### Deprecated version of terraform SDK

Running in debug mode could reveal that the provider implemntation uses a deprecated version of the terraform SDK, and we can read in the debug logs:

```bash
2024-02-24T20:56:46.798+0100 [WARN]  Provider "registry.terraform.io/terra-farm/virtualbox" produced an invalid plan for virtualbox_vm.debian_vm[0], but we are tolerating it because it is using the legacy plugin SDK.
    The following problems may be the cause of any confusing errors from downstream operations:
      - .status: planned value cty.StringVal("running") for a non-computed attribute
      - .network_adapter[0].device: planned value cty.StringVal("IntelPro1000MTServer") for a non-computed attribute
```

There is a major design issue, the terraform state contains a status that does not comply with reality: the `status` has `running` as a value, while the VM actually is not running.

About computed and non-computed attributes:
* https://discuss.hashicorp.com/t/computed-attributes-and-plan-modifiers/45830/3
* 

### Failure to create VM for powershell

```Powershell
virtualbox_vm.debian_vm[0]: Still creating... [9m43s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [9m53s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [10m3s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [10m13s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [10m23s elapsed]
2024-02-24T21:31:31.979+0100 [DEBUG] provider.terraform-provider-virtualbox_v0.2.2-alpha.1: pid-11644-utils.go:12: [ERROR] Create virtualbox VM debian_vm: exec: "false": executable file not found in %PATH%
2024-02-24T21:31:31.979+0100 [DEBUG] provider.terraform-provider-virtualbox_v0.2.2-alpha.1:
2024-02-24T21:31:32.003+0100 [ERROR] vertex "virtualbox_vm.debian_vm[0]" error: [ERROR] Create virtualbox VM debian_vm: exec: "false": executable file not found in %PATH%
╷
│ Error: [ERROR] Create virtualbox VM debian_vm: exec: "false": executable file not found in %PATH%
│
│
│   with virtualbox_vm.debian_vm[0],
│   on example.tf line 1, in resource "virtualbox_vm" "debian_vm":
│    1: resource "virtualbox_vm" "debian_vm" {
│
╵
2024-02-24T21:31:32.035+0100 [DEBUG] provider.stdio: received EOF, stopping recv loop: err="rpc error: code = Unavailable desc = error reading from server: EOF"
2024-02-24T21:31:32.061+0100 [DEBUG] provider: plugin process exited: path=.terraform.d/customised-providers/terraform-provider-virtualbox/bidule/terraform-provider-virtualbox_v0.2.2-alpha.1 pid=11644
2024-02-24T21:31:32.061+0100 [DEBUG] provider: plugin exited
PS C:\Users\Utilisateur\packman\terraform> VBoxManage --version
7.0.6r155176
PS C:\Users\Utilisateur\packman\terraform> go version
go version go1.18.3 windows/amd64
```

The exact golang instrcution which thros the error, is line 236 of the `resource_vm.go` source code file, and this is the instruction which invokes the VirtualBox VBoxManage executable file:

```Golang
	// Create VM instance
	name := d.Get("name").(string)
	vm, err := vbox.CreateMachine(name, machineFolder)
	if err != nil {
		return errLogf("Create virtualbox VM %s: %v\n", name, err)
	}
```

There, the `vbox.CreateMachine(name, machineFolder)` function comes from https://github.com/terra-farm/go-virtualbox, where I searched how the VboxManage executable file is looked up. I found [this line](https://github.com/terra-farm/go-virtualbox/blob/5b7d1140508ec16a3756bec4c04b5d28db6cae41/vbmgt.go#L49C22-L49C39), which suggests that the PATH env var is not set, but instead i could use the `VBOX_INSTALL_PATH` env var.

That's why I tried again executing my terraform like this : 

```Powershell
$Env:VBOX_INSTALL_PATH = "C:\jibl_vbox\install"

$Env:TF_CLI_CONFIG_FILE = "./.dev.tfrc"
$Env:TF_LOG = "debug"

terraform validate
terraform fmt

terraform plan -out="my.first.powershell.plan.tfplan"
terraform apply -auto-approve "my.first.powershell.plan.tfplan"
```

Finally, I found this issue showing others have experienced the same issue and solved it the same way, except that the `VBOX_INSTALL_PATH` has to be set as a system env var globally for windows, and the computer needs to be restarted: https://github.com/terra-farm/terraform-provider-virtualbox/issues/101

In my case, I didn't have to create the System wide env var, setting it in the Powershell session ws enough, and the VM is indeed created, yet, I still get an error to investigate :

```Powershell
virtualbox_vm.debian_vm[0]: Still creating... [5m50s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [6m0s elapsed]
2024-02-24T22:40:27.122+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stdout="Virtual machine 'debian_vm' is created and registered.
UUID: 7b4ad45e-6929-4241-8b56-3631debdf052
Settings file: 'C:\Users\Utilisateur\.terraform\virtualbox\machine\debian_vm\debian_vm.vbox'"
2024-02-24T22:40:27.255+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=0
2024-02-24T22:40:27.255+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%...
virtualbox_vm.debian_vm[0]: Still creating... [6m10s elapsed]
virtualbox_vm.debian_vm[0]: Still creating... [6m20s elapsed]
2024-02-24T22:40:46.849+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=10
2024-02-24T22:40:46.849+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%...20%...30%...40%...50%...60%...70%...80%...90%...
2024-02-24T22:40:47.274+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=100
2024-02-24T22:40:47.275+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%
2024-02-24T22:40:47.296+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stdout="Clone medium created in format 'VMDK'. UUID: 46c04b6b-e008-4b46-9877-55a3f4abcdb3"
2024-02-24T22:40:47.417+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=0
2024-02-24T22:40:47.418+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%...
2024-02-24T22:40:47.518+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=10
2024-02-24T22:40:47.518+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%...20%...30%...40%...50%...60
2024-02-24T22:40:47.522+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%...70%...80%...90%...
2024-02-24T22:40:47.811+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=100
2024-02-24T22:40:47.812+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=%
2024-02-24T22:40:47.817+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stdout="Clone medium created in format 'VMDK'. UUID: 0ef65129-ca6b-48e2-b70a-70c151235381"
2024-02-24T22:40:49.587+0100 [DEBUG] provider.terraform-provider-virtualbox_v0.2.2-alpha.1: pid-12188-resource_vm.go:605: [DEBUG] Network adapter: {Network: Hardware:82545EM HostInterface: MacAddr:}
2024-02-24T22:40:50.447+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=VBoxManage.exe
2024-02-24T22:40:50.447+0100 [WARN]  unexpected data: registry.terraform.io/terra-farm/virtualbox:stderr=": error: Invalid type '' specfied for NIC 1"
2024-02-24T22:40:50.475+0100 [DEBUG] provider.terraform-provider-virtualbox_v0.2.2-alpha.1: pid-12188-utils.go:12: [ERROR] Setup VM properties: exit status 1
2024-02-24T22:40:51.235+0100 [ERROR] vertex "virtualbox_vm.debian_vm[0]" error: [ERROR] Setup VM properties: exit status 1
╷
│ Error: [ERROR] Setup VM properties: exit status 1
│
│   with virtualbox_vm.debian_vm[0],
│   on example.tf line 1, in resource "virtualbox_vm" "debian_vm":
│    1: resource "virtualbox_vm" "debian_vm" {
│
╵
2024-02-24T22:40:51.680+0100 [DEBUG] provider.stdio: received EOF, stopping recv loop: err="rpc error: code = Unavailable desc = error reading from server: EOF"
2024-02-24T22:40:51.710+0100 [DEBUG] provider: plugin process exited: path=.terraform.d/customised-providers/terraform-provider-virtualbox/bidule/terraform-provider-virtualbox_v0.2.2-alpha.1 pid=12188
2024-02-24T22:40:51.710+0100 [DEBUG] provider: plugin exited
PS C:\Users\Utilisateur\packman\terraform>
```

## Conclusions


## ANNEX - TerraformRc: How `provider_installation.dev_overrides` works

I found it, it is simple, the path on the right, must be the path of a folder, and that folder must contains the executable file:

Let's say you have a terraformrc config file like : 

```Hcl
provider_installation {
    dev_overrides {
      "terra-farm/virtualbox" = "./.terraform.d/customised-providers/terraform-provider-virtualbox/bidule"
    }
}
```

and in your `providers.tf`:

```Hcl

terraform {

  required_providers {
    virtualbox = {
      source = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {
  # Configuration options
}
```

and you run : 

```bash

export TF_CLI_CONFIG_FILE=$(pwd)/.dev.tfrc

export TF_LOG=debug

terraform validate
terraform fmt

terraform plan -out=my.first.plan.tfplan
terraform apply -auto-approve "my.first.plan.tfplan"


```

* With the example above, terraform will lookup the executable file like this:
  * It will search in the `./.terraform.d/customised-providers/terraform-provider-virtualbox/` folder,
  * it will search for an executable file named exactly `terraform-${TF_PLUGIN_TYPE}-${CLOUD_PROVIDER_NAME}_v${TF_PROVIDER_VERSION}`, where :
    * `TF_PROVIDER_VERSION` is picked up from your `providers.tf`, the value of the `terraform.required_providers.virtualbox.version` attribute.
    * `CLOUD_PROVIDER_NAME` is picked up from your `providers.tf` file, the value of the `terraform.required_providers.virtualbox.source` attribute, only the string on the right of the (last) slash character.

And that's it. So in the example above, `terraform` will lookup the `./.terraform.d/customised-providers/terraform-provider-virtualbox/bidule/terraform-provider-virtualbox_v0.2.2-alpha.1` file.

