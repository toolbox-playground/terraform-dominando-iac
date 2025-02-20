terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"
}

# Criando a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MinhaVPC"
  }
}

# Criando a primeira sub-rede
resource "aws_subnet" "subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Subnet-1"
  }
}

# Criando a segunda sub-rede
resource "aws_subnet" "subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Subnet-2"
  }
}
