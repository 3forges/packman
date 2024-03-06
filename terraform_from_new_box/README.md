# The Terraform, with the new box

## How to run

Required:

* You have built from source the terraform provider, as intructed in the [terraform study README.md](./../terraform/README.md)
* You have built the new Vagrant box, as intructed in the [packer vagrant builder study README.md](./../packer/README.md)

After you created the new vagrant box, using packer:

* you will use the serve `nodejs` simple http server (`npm i -g serve`):
  * to serve the content of the [`<rootfolderwhere you git cloned this repo>/packer/golden/debian12_remote`](./../packer/golden/debian12_remote/) folder, 
  * where there is the `package.box` resulting of running the packer build. 
  * Such that <http://localhost:3000/package.box>, will serve the new Vagrant box.
* Then, you will run the terraform in this folder.

> _Note: You will run terraform using only powershell: terraform on windows has very well known issue with files and folder path_

### Run the teraform

* In a powershell session, Execute:

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

terraform plan -out="my.first.powershell.plan.tfplan"
terraform apply -auto-approve "my.first.powershell.plan.tfplan"


```

And you will get the 2 Virtual machines.
