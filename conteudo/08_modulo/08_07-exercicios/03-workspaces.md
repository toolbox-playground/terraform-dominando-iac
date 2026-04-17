# Exercício 03 - Workspaces para ambientes

*(Integra `exercicios/2_intermediarios/14.md` e `exercicios/2_intermediarios/20.md` - Workspaces.)*

## Objetivo

Usar workspaces para gerenciar `dev`, `staging` e `prod` com um único código, onde `instance_type` varia por ambiente.

## Tarefas

1. Crie `main.tf`:

   ```hcl
   terraform {
     required_version = ">= 1.5"
     required_providers {
       aws = { source = "hashicorp/aws", version = "~> 5.0" }
     }
   }

   provider "aws" {
     region = "us-east-1"
   }

   locals {
     instance_type_por_ws = {
       default = "t3.micro"
       dev     = "t3.micro"
       staging = "t3.small"
       prod    = "t3.large"
     }

     instance_type = local.instance_type_por_ws[terraform.workspace]
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
     instance_type = local.instance_type

     tags = {
       Name     = "web-${terraform.workspace}"
       Ambiente = terraform.workspace
     }
   }

   output "ambiente" {
     value = terraform.workspace
   }

   output "instance_type_escolhido" {
     value = local.instance_type
   }
   ```

2. Execute:

   ```bash
   terraform init
   terraform workspace new dev
   terraform apply       # usa t3.micro

   terraform workspace new staging
   terraform apply       # usa t3.small

   terraform workspace new prod
   terraform apply       # usa t3.large
   ```

3. Liste: `terraform workspace list`.

4. Alterne e veja os states isolados:

   ```bash
   terraform workspace select dev
   terraform state list

   terraform workspace select prod
   terraform state list
   ```

5. Destrua tudo no final:

   ```bash
   for ws in dev staging prod; do
     terraform workspace select $ws
     terraform destroy -auto-approve
   done
   ```

## Adicione validação

Após o exercício funcionar, adicione um `check`:

```hcl
check "workspace_valido" {
  assert {
    condition     = contains(["dev", "staging", "prod"], terraform.workspace)
    error_message = "Rode em dev, staging ou prod — não em default."
  }
}
```

## Perguntas

1. Onde ficam armazenados os states no backend local para workspaces não-default?
2. Se você não troca o workspace antes de `apply`, o que acontece?
3. Por que workspaces **não** são a melhor escolha para produção corporativa?
4. Como ficaria o mesmo exercício com **diretórios separados** em vez de workspaces?
