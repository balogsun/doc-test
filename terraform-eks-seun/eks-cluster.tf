#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "pjct-cluster" {
  name = "pjct-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "pjct-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.pjct-cluster.name
}

resource "aws_iam_role_policy_attachment" "pjct-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.pjct-cluster.name
}

resource "aws_security_group" "pjct-cluster" {
  name        = "pjct-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.pjct-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pjct-cluster"
  }
}

resource "aws_security_group_rule" "pjct-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.pjct-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "pjct-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.pjct-cluster.arn
  
  version = var.eks_version

  vpc_config {
    security_group_ids = [aws_security_group.pjct-cluster.id]
    subnet_ids         = aws_subnet.pjct-private-subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.pjct-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.pjct-cluster-AmazonEKSServicePolicy,
  ]
}
#
#resource "aws_eks_cluster" "pjct-cluster" {
#  name     = var.cluster_name
#  role_arn = aws_iam_role.pjct-cluster.arn
#
#  vpc_config {
#    security_group_ids = [aws_security_group.pjct-cluster.id]
#    subnet_ids         = aws_subnet.pjct-public-subnet[*].id
#    endpoint_private_access = false  # Ensure the EKS cluster endpoint is accessible publicly
#    endpoint_public_access  = true   # Ensure the EKS cluster endpoint is publicly accessible
#  }
#}
