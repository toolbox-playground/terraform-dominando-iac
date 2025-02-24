provider "aws" {
region = "us-east-1" # Erro: Indentação incorreta
}

resource "aws_eks_cluster" "example" {
name     = "meu-cluster" # Erro: Espaçamento inconsistente
    role_arn=   "arn:aws:iam::123456789012:role/EKSClusterRole" # Erro: Espaços extras ao redor do '='

  vpc_config {
    subnet_ids = ["subnet-abc123", "subnet-def456"] # Erro: Formatação incorreta da lista
  }
}

resource "aws_iam_role" "eks_role" {
  name      = "eks-cluster-role"
  assume_role_policy= """{
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
  }""" # Erro: Espaçamento inconsistente
}
