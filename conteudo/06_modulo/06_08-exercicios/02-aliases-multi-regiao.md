# Exercício 02 - Aliases e multi-região

## Objetivo

Provisionar um bucket S3 em **duas regiões** AWS (`us-east-1` e `eu-west-1`) usando aliases do provider.

## Tarefas

1. Declare dois blocos `provider "aws"`:
   - Um sem alias (`us-east-1`).
   - Um com `alias = "eu"` em `eu-west-1`.
2. Crie:
   - `aws_s3_bucket.principal` — usa o provider default.
   - `aws_s3_bucket.replica` — usa `provider = aws.eu`.
3. Adicione `random_id` para sufixar os nomes (exercício anterior).
4. Rode `plan`, identifique em que ordem e em que região cada bucket vai nascer.
5. Aplique e verifique no console da AWS (ou via `aws s3api get-bucket-location --bucket NOME`).
6. Tente omitir o `provider = aws.eu` no recurso `replica` e veja o erro.
7. Destrua.

## Perguntas

1. Se você trocar o alias por "europe", o que precisa mudar?
2. Pode um recurso usar dois providers simultaneamente? Por quê?
3. O `default_tags` do provider default se aplica ao recurso com alias? (Pista: cada `provider` tem suas próprias tags.)

## Solução referência

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

resource "random_id" "sufixo" {
  byte_length = 4
}

resource "aws_s3_bucket" "principal" {
  bucket = "demo-principal-${random_id.sufixo.hex}"
}

resource "aws_s3_bucket" "replica" {
  provider = aws.eu
  bucket   = "demo-replica-${random_id.sufixo.hex}"
}
```
