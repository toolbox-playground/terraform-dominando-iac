# Exercício 03 - Composição via `terraform_remote_state`

## Objetivo

Compor dois projetos Terraform: um que cria uma VPC (estado independente) e outro que provisiona uma instância EC2 consumindo os outputs da VPC.

## Pré-requisitos

- Backend S3 + DynamoDB já configurado (exercício 01).

## Parte 1: Projeto `rede/`

```hcl
# rede/versions.tf
terraform {
  required_version = ">= 1.5"
  backend "s3" {
    bucket         = "toolbox-terraform-tfstate"
    key            = "rede/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "toolbox-terraform-locks"
    encrypt        = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
  tags       = { Name = "rede-demo" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "public-1a" }
}

output "vpc_id"    { value = aws_vpc.this.id }
output "subnet_id" { value = aws_subnet.public.id }
```

Aplique e confirme que o state está no S3.

## Parte 2: Projeto `app/`

```hcl
# app/versions.tf
terraform {
  required_version = ">= 1.5"
  backend "s3" {
    bucket         = "toolbox-terraform-tfstate"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "toolbox-terraform-locks"
    encrypt        = true
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "terraform_remote_state" "rede" {
  backend = "s3"
  config = {
    bucket = "toolbox-terraform-tfstate"
    key    = "rede/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = data.terraform_remote_state.rede.outputs.subnet_id

  tags = { Name = "app-demo" }
}

output "instance_id" { value = aws_instance.web.id }
output "vpc_id"      { value = data.terraform_remote_state.rede.outputs.vpc_id }
```

Aplique. A instância deve nascer dentro da VPC criada pelo projeto `rede/`.

## Validação

```bash
# No app/
terraform output
```

O `vpc_id` deve ser o mesmo que `terraform output` no diretório `rede/`.

## Perguntas

1. Se você destruir `rede/` primeiro, o que acontece com o state do `app/`?
2. Se a VPC for deletada manualmente na AWS, o `data.terraform_remote_state` ainda retorna o valor? Por quê?
3. Qual a alternativa a `terraform_remote_state`? (Pista: data sources diretos da cloud.)
4. Quais permissões IAM são necessárias no bucket/DynamoDB para cada projeto?
