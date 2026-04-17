# Exercício 04 - Autenticação segura do provider

*(Integra `exercicios/2_intermediarios/19.md` - Instalação do provider e variáveis de ambiente.)*

## Objetivo

Configurar um projeto onde:

- Nenhuma credencial aparece no código.
- `region` e outras configs vêm de variáveis.
- O provider é autenticado via variáveis de ambiente/profile.

## Tarefas

1. Crie um `versions.tf` com `required_providers` para `hashicorp/aws ~> 5.0`.
2. Declare:
   ```hcl
   variable "aws_region" {
     type    = string
     default = "us-east-1"
   }

   variable "instance_type" {
     type    = string
     default = "t3.micro"
   }
   ```
3. Configure `provider "aws" { region = var.aws_region }`.
4. Crie um `aws_instance` usando `var.instance_type`.
5. Antes de rodar `init`, exporte no shell:
   ```bash
   export AWS_ACCESS_KEY_ID="..."
   export AWS_SECRET_ACCESS_KEY="..."
   # OU
   export AWS_PROFILE="empresa-dev"
   ```
6. Também teste passando `TF_VAR_instance_type=t3.small terraform plan`.

## Perguntas

1. Qual a prioridade entre: variável no `.tfvars`, variável no ambiente (`TF_VAR_*`), variável default, flag `-var`?
2. Por que `AWS_PROFILE` é preferível a `AWS_ACCESS_KEY_ID` em dev local?
3. Como garantir em CI que nenhum secret vai para log?

## Cenário extra: assume role

Altere o provider para:

```hcl
provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/terraform-dev"
    session_name = "terraform-${terraform.workspace}"
  }
}
```

Documente no README do projeto quem precisa ter permissão `sts:AssumeRole` para essa role.
