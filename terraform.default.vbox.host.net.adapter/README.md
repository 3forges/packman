# The Terraform part

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
