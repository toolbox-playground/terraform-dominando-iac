# Exercício 02 - Configurar o provider AWS

## Contexto

Sua equipe precisa provisionar recursos na AWS utilizando Terraform. Para isso, você deve preparar o diretório inicial com a configuração mínima de provider e inicializar o ambiente.

## Objetivo

Criar os arquivos iniciais de um projeto Terraform com provider AWS configurado e executar `terraform init` com sucesso.

## Tarefas

1. Crie um diretório novo para o projeto (ex.: `~/meu-primeiro-terraform`).

2. Dentro dele, crie o arquivo `versions.tf`:

   ```hcl
   terraform {
     required_version = ">= 1.5"

     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }

   provider "aws" {
     region = "us-east-1"
   }
   ```

3. Exporte credenciais da AWS como variáveis de ambiente (obtenha no console AWS → IAM → Access Keys):

   **Linux/macOS:**

   ```bash
   export AWS_ACCESS_KEY_ID="AKIA..."
   export AWS_SECRET_ACCESS_KEY="..."
   export AWS_DEFAULT_REGION="us-east-1"
   ```

   **Windows PowerShell:**

   ```powershell
   $env:AWS_ACCESS_KEY_ID = "AKIA..."
   $env:AWS_SECRET_ACCESS_KEY = "..."
   $env:AWS_DEFAULT_REGION = "us-east-1"
   ```

4. Execute:

   ```bash
   terraform init
   terraform validate
   ```

5. A saída de `validate` deve dizer `Success! The configuration is valid.`.

## Critério de conclusão

- Pasta `.terraform/` foi criada após o `init`.
- Provider AWS aparece baixado em `.terraform/providers/registry.terraform.io/hashicorp/aws/...`.
- `terraform validate` retorna `Success!`.

## Atenção

- **Nunca** coloque chaves AWS diretamente em arquivos `.tf` commitados. Use env vars, perfis (`~/.aws/credentials`) ou serviços como AWS SSO.

## Referências

- Tópico [02_10 - Configurações do Terraform](../02_10-configuracoes-terraform.md)
- [Provider AWS - autenticação](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
