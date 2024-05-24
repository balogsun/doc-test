# Prerequisites:
### 1. Install AWS CLI that is compatible with you sandbox OS - Using AWS documentation. https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

### 2. Install terraform that is compatible with you sandbox OS - https://developer.hashicorp.com/terraform/install

    The terraform modules below will create a VPC with 3 private and public subnets, and will also Deploy an EKS cluster (version 1.30) in that VPC.

    Below is a detailed explanation of each resource and how they work together:

### Step 1:
 - Create a `provider.tf` file to configure the AWS provider to use the `ca-central-1` region and retrieves information about the current region and its available availability zones.

  ```hcl
  provider "aws" {
    region  = "ca-central-1"
  }

  data "aws_region" "current" {}

  data "aws_availability_zones" "available" {}
  ```

 - Create a `worker-node.tf` file configures an IAM role with necessary policies for EKS worker nodes, sets up an EKS node group with specific instance types, subnets, scaling parameters, including desired size, minimum size, and maximum size, and SSH access.
 
 - Create a `variables.tf` file defines four input variables for customizing an AWS EKS cluster deployment:

   - **`cluster-name`**: Sets the default EKS cluster name (`"pjct-cluster"`).
   - **`eks_version`**: Specifies the Kubernetes version (`"1.30"`).
   - **`key_pair_name`**: Defines the AWS key pair name for SSH access (`"project-key"`).
   - **`eks_node_instance_type`**: Determines the instance type for EKS nodes (`"t2.medium"`).

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

 - Create `cluster.tf` file defines resources for setting up an AWS EKS (Elastic Kubernetes Service) cluster with the necessary IAM roles, security groups, and the cluster itself. 

- Create a `vpc.tf` file creates a Virtual Private Cloud (VPC) with public and private subnets distributed across three availability zones, configures internet access through an internet gateway, sets up NAT gateways for outbound internet access from private subnets, associates route tables for proper traffic routing, and creates resources such as route table associations, NAT gateway routes, and Elastic IP addresses.

#### Step 2: Run the command "aws configure" to set up your AWS Command Line Interface (CLI) with your AWS credentials and default settings, including your Access Key ID, Secret Access Key, default region, and default output format.

```sh
aws configure

Access Key ID: *********************
Secret key: ******************************************
Deafult region Name [none] ca-central-1
Default output format [none]
```

### Step 3: Clone this repo to your directory, change directory to **`terraform-eks-seun`** and run terraform command to initialize your modules.

```sh
terraform init
```

###  Step 4: Run terraform commands to create the clusters, vpc and other resources.

```sh
terraform plan

terraform apply -auto-approve
```
![Screenshot 2024-05-24 133331](https://github.com/balogsun/doc-test/assets/125329091/49de57cc-147f-4050-856f-5b8aca981247)

###  Step 5:  Run the command 
```sh
aws eks update-kubeconfig --region ca-central-1 --name pjct-cluster
```
to update the kubeconfig file with the necessary configuration to access the EKS cluster named "pjct-cluster" in the AWS region "ca-central-1".

### Step 6:  Confirm cluster and nodes are running with below command:
```sh
aws eks list-clusters

kubectl get nodes -o wide
```
![Screenshot 2024-05-24 134454](https://github.com/balogsun/doc-test/assets/125329091/cc1c766e-5c32-4fd3-aacc-ac3e7a7dd4fb)

### Cluster setup
![Screenshot 2024-05-24 134307](https://github.com/balogsun/doc-test/assets/125329091/757190d8-d3f1-4ad9-9d9c-0c935b36d5a8)

### VPC setup
![Screenshot 2024-05-24 133546](https://github.com/balogsun/doc-test/assets/125329091/cb252202-34ea-475e-89e2-cc531dda8867)

### Node group config
![Screenshot 2024-05-24 134242](https://github.com/balogsun/doc-test/assets/125329091/bb8c9e0d-8d6c-4bbb-84a5-5758bd771c30)

### Step 7: We will test two application deployment using two configured manifest files, **`python-flask1.yml`** and **`hello-world.yaml`**

- Change directory to **`deployments`**, and run the commands below to run these deployments. 
Each deployment will create two replicas and will be exposed with the load balancer.

```sh
kubectl apply -f python-flask1.yml

kubectl apply -f hello-world.yaml
```

### Step 8: Get the list of services running and use the load balancer url information to access the application over the web.

```sh
kubectl get svc
```
![Screenshot 2024-05-24 140054](https://github.com/balogsun/doc-test/assets/125329091/e20ebe39-33c3-4ebe-abae-5afd127e18b9)

The application is now accessible on the web.
### - python-flask-app
![Screenshot 2024-05-24 140116](https://github.com/balogsun/doc-test/assets/125329091/0bebc530-2cab-4164-b711-d3a54a60008f)

### - hello-kubernetes-app
![Screenshot 2024-05-24 140136](https://github.com/balogsun/doc-test/assets/125329091/29f1a823-dce1-41a6-9491-92df38dfa54b)


## Step 9: Clean Up
- Delete the deployment
```sh
kubectl delete -f python-flask1.yml

kubectl delete -f hello-world.yaml
```
- Clean up the cluster
```sh
terraform destroy auto-approve
```
