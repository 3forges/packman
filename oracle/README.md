# The Terraform, with the new box

## How to run

### Run the teraform

* In a powershell session, Execute:

```PowerShell
# ---
#  
$Env:TF_LOG = "debug"


terraform init
terraform validate
terraform fmt

terraform plan -out="my.first.powershell.plan.tfplan"
terraform apply -auto-approve "my.first.powershell.plan.tfplan"


```

* Destroy it all:

```PowerShell

terraform plan -destroy -out="my.first.destroy.powershell.plan.tfplan"
terraform apply "my.first.destroy.powershell.plan.tfplan"

```

## Before installing Docker: IP tables

For now, I think the Ingress Rules I setup are good, as far as I understand, and for minio web app access on 9001 port.

I prepare this section, because according my readigs, it seems it might turn out that I need to run an Iptables setup in the VM, to complete the Ingress rules.

If I setup IP tables for my VM, then I have to do it before installing docker, because docker does its own networking setup.

And if so, up until now I figured out that the setup should be something like this, in the VM (but i need to work on that part to understand clearly what i am doing):

```bash
sudo iptables -I INPUT -p tcp -m tcp --dport 9001 -j ACCEPT
sudo  iptables-save | sudo tee -a /etc/iptables/rules.v4

```

## Install docker in VM

* this works: https://docs.docker.com/engine/install/ubuntu/

* test a container:

```bash
sudo ~/minio/data
sudo docker run -d \
   -p 0.0.0.0:9000:9000 \
   -p 0.0.0.0:9001:9001 \
   --name minio \
   -v ~/minio/data:/data \
   -e "MINIO_ROOT_USER=ROOTNAME" \
   -e "MINIO_ROOT_PASSWORD=CHANGEME123" \
   quay.io/minio/minio server /data --console-address ":9001"
```


## Set up

RSA key pair for provider authentication (then add the pub key to user's API KEys):

```bash
# --- private key
openssl genrsa -out ~/.oci/clef_oracle_cloud.pem 2048
chmod 600 ~/.oci/clef_oracle_cloud.pem
# --- associated pub key
openssl rsa -pubout -in ~/.oci/clef_oracle_cloud.pem -out $HOME/.oci/clef_oracle_cloud.public.pem
```

* Now VM ssh key pair

```bash
mkdir -p ~/.decoderleco/compte.oci.a.bobo/
ssh-keygen -t rsa -N "" -b 2048 -C "jb@boboscloud.on.oracle.io" -f ~/.decoderleco/compte.oci.a.bobo/id_rsa
```

## Networking 


![netw](./docs/images/network_scenario_a_regional.svg)

* You do need all of those to get access to your VM hitting public IP Address:
  * Internet Gateway and NAT Gateway
  * a VCN RouteTable

* Then you need to add an Ingress Rule(s) for your VCN, in your terraform code, according:
  * <https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list>
  * <https://github.com/search?q=resource+oci_core_security_list&type=code>
  * <https://github.com/oracle/terraform-provider-oci/blob/e95fac9bee135b539b6db97395984677373231ff/infrastructure/resource_discovery/transient/core.tf#L441C1-L470C4>
  * <https://github.com/hiddify/Hiddify-Manager/blob/dd7517e0fdc3d99344bb62f5873a4bf4941399c1/btn-deploy/oracle/security-lists.tf#L5>
  * <https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/apache-on-ubuntu/01oci-ubuntu-apache-summary.htm>

then to modify the state of my inrfa, after just adding the security rules, with ingress rules, I ran:

```bash
terraform validate
terraform fmt

terraform plan -out="add.ingress.test1.powershell.plan.tfplan"
terraform apply -auto-approve "add.ingress.test1.powershell.plan.tfplan"

```

* About configuring authorization of external access to http port numbers in the VM:
  * https://stackoverflow.com/questions/62326988/cant-access-oracle-cloud-always-free-compute-http-port
  * https://docs.oracle.com/en-us/iaas/developer-tutorials/tutorials/apache-on-ubuntu/01oci-ubuntu-apache-summary.htm
  * https://abeerm171.medium.com/part-2-applying-security-list-to-subnets-in-oracle-cloud-using-terraform-82bd0c087eac
  * https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list

## ANNEX: always free resources

* <https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm>

## ANNEX References

* maybe we miss the gateway : https://dev.to/farisdurrani/using-terraform-to-deploy-an-oci-compute-instance-harder-5c52
* error about missing ShapeConfig: https://github.com/oracle/terraform-provider-oci/issues/1917

## The last error

We are for now at this error about the OS image:

```bash
PS C:\Users\Utilisateur\packman\oracle> terraform apply -auto-approve "my.first.powershell.plan.tfplan"
oci_core_instance.ubuntu_instance: Creating...
╷
│ Error: 400-InvalidParameter, Shape VM.Standard.A1.Flex is not valid for image ocid1.image.oc1.eu-paris-1.aaaaaaaaf7irdvozuzmwyvbfacdivomj52x65vr6tlg62i6er323sevazdqq.
│ Suggestion: Please update the parameter(s) in the Terraform config as per error message Shape VM.Standard.A1.Flex is not valid for image ocid1.image.oc1.eu-paris-1.aaaaaaaaf7irdvozuzmwyvbfacdivomj52x65vr6tlg62i6er323sevazdqq.
│ Documentation: https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
│ API Reference: https://docs.oracle.com/iaas/api/#/en/iaas/20160918/Instance/LaunchInstance
│ Request Target: POST https://iaas.eu-paris-1.oraclecloud.com/20160918/instances
│ Provider version: 5.32.0, released on 2024-03-06.
│ Service: Core Instance
│ Operation Name: LaunchInstance
│ OPC request ID: ec9f94d17fecd6357f6c3f29e0d6c40a/64CEA7A3AC23DF94CE536456D828851C/F9F9EB778E0EC4EC521C2A2A38BC6349
│
│
│   with oci_core_instance.ubuntu_instance,
│   on main.tf line 55, in resource "oci_core_instance" "ubuntu_instance":
│   55: resource "oci_core_instance" "ubuntu_instance" {
│
╵
PS C:\Users\Utilisateur\packman\oracle>
```

* https://docs.oracle.com/en-us/iaas/Content/Rover/Compute/Image/get_image-shape-compatibility-entry.htm

* https://docs.oracle.com/en-us/iaas/Content/Compute/References/images.htm

* https://docs.oracle.com/en-us/iaas/tools/oci-cli/3.37.12/oci_cli_docs/cmdref/compute/image-shape-compatibility-entry/list.html

* https://martincarstenbach.com/2018/11/26/log-in-to-ubuntu-vms-in-oracle-cloud-infrastructure/

* https://stackoverflow.com/questions/61375652/oracle-cloud-instance-connectivity-issue