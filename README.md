
### Install AWS CLI that is compatible with you sandbox OS - Using AWS documentation. https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### Install terraform that is compatible with you sandbox OS - https://developer.hashicorp.com/terraform/install

The terraform modules below will create a VPC with 3 private and public subnets, ans will aslo Deploy an EKS cluster (version 1.30) in that VPC.

Below is a detailed explanation of each resource and how they work together:

Create a `provider.tf` file configures the AWS provider to use the `ca-central-1` region and retrieves information about the current region and its available availability zones.

```hcl
provider "aws" {
  region  = "ca-central-1"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
```

Create a `worker-node.tf` file configures an IAM role with necessary policies for EKS worker nodes, sets up an EKS node group with specific instance types, subnets, scaling parameters, including desired size, minimum size, and maximum size, and SSH access.
 
Create a `variables.tf` file defines four input variables for customizing an AWS EKS cluster deployment:

- **`cluster-name`**: Sets the default EKS cluster name (`"pjct-cluster"`).
- **`eks_version`**: Specifies the Kubernetes version (`"1.30"`).
- **`key_pair_name`**: Defines the AWS key pair name for SSH access (`"project-key"`).
- **`eks_node_instance_type`**: Determines the instance type for EKS nodes (`"t2.medium"`).

These variables allow me to easily customize and reuse your Terraform configuration across different environments.

```hcl
variable "cluster-name" {
  default = "pjct-cluster"
  type    = string
}
variable "eks_version" {
  default = "1.30"
  type    = string
}
variable "key_pair_name" {
  default = "project-key"
}
variable "eks_node_instance_type" {
  default = "t2.medium"
}
```

Create `cluster.tf` file defines resources for setting up an AWS EKS (Elastic Kubernetes Service) cluster with the necessary IAM roles, security groups, and the cluster itself. 

Dependencies ensure that the IAM role policies are attached before creating the EKS cluster.

The `vpc.tf` file creates a Virtual Private Cloud (VPC) with public and private subnets distributed across three availability zones, configures internet access through an internet gateway, sets up NAT gateways for outbound internet access from private subnets, associates route tables for proper traffic routing, and creates resources such as route table associations, NAT gateway routes, and Elastic IP addresses.

### Clone this repo to your directory and run terraform command to initialize your modules.

```sh
terraform init
```

### Run terraform commands to create the clusters, vpc and other resources.

```sh
terraform plan

terraform apply -auto-approve
```

#### Run the command "aws configure" to set up your AWS Command Line Interface (CLI) with your AWS credentials and default settings, including your Access Key ID, Secret Access Key, default region, and default output format.

```sh
aws configure

Access Key ID: *********************
Secret key: ******************************************
Deafult region Name [none] ca-central-1
Default output format [none]
```

#### Run the command 
```sh aws eks update-kubeconfig --region ca-central-1 --name pjct-cluster
```
to update the kubeconfig file with the necessary configuration to access the EKS cluster named "pjct-cluster" in the AWS region "ca-central-1".

#### Confirm cluster and nodes are running with below command:
```sh
aws eks list-clusters

kubectl get nodes -o wide
```

We will test two application deployment using two configured manifest files, **`python-flask1.yml`** and **`hello-world.yaml`**

### Run the commands below to run these deployments. 
Each deployment will create two replicas and will be exposed with the load balancer.

```sh
kubectl apply -f python-flask1.yml

kubectl apply -f hello-world.yaml
```

### Get the list of services running and use the load balancer url information to access the application over the web.

```sh
kubectl get svc
```

The application is now accessible on the web.

## Clean Up
- Delete the deployment
```sh
kubectl delete -f python-flask1.yml

kubectl delete -f hello-world.yaml
```
- Clean up the cluster
```sh
terraform destroy auto-approve
```
