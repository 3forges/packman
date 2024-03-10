# The Terraform, with the new box

## How to run

### Run the teraform

* In a powershell session, Execute:

```Powershell
# ---
#  
$Env:TF_LOG = "debug"


terraform init
terraform validate
terraform fmt

terraform plan -out="my.first.powershell.plan.tfplan"
terraform apply -auto-approve "my.first.powershell.plan.tfplan"


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