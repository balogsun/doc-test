#
# Variables Configuration
#

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
