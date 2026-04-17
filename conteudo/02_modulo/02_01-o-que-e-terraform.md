# 02_01 - O que é o Terraform

## Definição

**Terraform** é uma ferramenta de **Infraestrutura como Código (IaC)** criada pela HashiCorp que permite **definir, provisionar e gerenciar** infraestrutura usando arquivos de configuração declarativos escritos em **HCL (HashiCorp Configuration Language)**.

Em uma frase: com Terraform você escreve arquivos `.tf` dizendo **o que** sua infraestrutura deve ser, e a ferramenta se encarrega de **chegar e manter** esse estado em qualquer nuvem ou sistema com API.

## Origem

- **2014**: HashiCorp lança o Terraform (versão 0.1).
- **2021**: Terraform atinge a versão 1.0, consolidando o HCL como interface principal e garantindo estabilidade da API.
- **2023**: HashiCorp muda a licença do Terraform de MPL 2.0 para BSL (Business Source License), criando polêmica na comunidade.
- **2023**: a Linux Foundation cria o **OpenTofu**, fork open source do Terraform mantido pela comunidade.
- Terraform segue o **líder de mercado** em IaC multi-cloud, com ecossistema maduro de providers e módulos.

Para efeitos deste curso, tudo que aprendemos se aplica igualmente ao OpenTofu — a sintaxe e o workflow são idênticos.

## O que faz um arquivo Terraform parecer

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

resource "aws_s3_bucket" "logs" {
  bucket = "logs-producao-2026"
}
```

Três ingredientes:

1. **Bloco `terraform`** — configura a própria ferramenta (versão mínima, providers obrigatórios, backend de state).
2. **Bloco `provider`** — configura a integração com uma nuvem/plataforma específica (AWS, GCP, Azure, Kubernetes, GitHub, Datadog, etc.).
3. **Bloco `resource`** — declara um recurso a ser gerenciado (bucket, VM, DNS, role IAM, etc.).

## HCL — HashiCorp Configuration Language

HCL é uma linguagem de configuração declarativa projetada para ser:

- **Legível por humanos** (diferente de JSON puro).
- **Parseable por máquinas** (ferramentas podem gerar e consumir HCL).
- **Rica o suficiente** para comportar expressões, loops (`for_each`, `count`), condicionais e funções.

Exemplo de expressividade HCL:

```hcl
resource "aws_instance" "web" {
  for_each      = toset(["us-east-1a", "us-east-1b"])
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.ambiente == "prod" ? "m5.large" : "t3.micro"
  availability_zone = each.key

  tags = {
    Name = "web-${each.key}"
  }
}
```

O Módulo 5 se dedica inteiramente a HCL. O Módulo 9 cobre a parte avançada (loops, expressões, dinâmicos).

## Posicionamento no ecossistema IaC

| Ferramenta | Paradigma | Escopo | Linguagem | Observação |
|-----------|-----------|--------|-----------|------------|
| **Terraform** | Declarativo | Multi-cloud, SaaS, on-prem | HCL | Líder de mercado |
| **OpenTofu** | Declarativo | Idem Terraform | HCL | Fork open source |
| **CloudFormation** | Declarativo | AWS only | YAML/JSON | Nativo AWS |
| **Azure Resource Manager** | Declarativo | Azure only | JSON/Bicep | Nativo Azure |
| **Google Cloud Deployment Manager** | Declarativo | GCP only | YAML/Jinja | Nativo GCP (sendo sucedido por outros) |
| **Pulumi** | Imperativo/Declarativo | Multi-cloud | Python, TS, Go, C# | Usa linguagens de programação reais |
| **Ansible** | Procedural | Config management + infra | YAML | Forte em configuração de SO |
| **Chef / Puppet** | Modelo próprio | Config management | Ruby/DSL | Gerações anteriores |

**Terraform não substitui 100%** ferramentas como Ansible (que ainda brilha em gerenciar configuração *dentro* de uma VM). O uso combinado é comum: **Terraform cria a VM, Ansible configura a VM** (ou, preferencialmente, uma AMI gerada por Packer).

## O que o Terraform **não** é

- **Não é** um orquestrador de containers (isso é Kubernetes, ECS, Nomad).
- **Não é** uma ferramenta de configuração de pacotes dentro de uma VM (isso é Ansible/Chef/Puppet).
- **Não é** um scheduler de aplicações (isso é Kubernetes).
- **Não é** um pipeline de CI/CD (embora seja consumido por um — ver Módulo 11).
- **Não é** mágico: se a API da nuvem não suporta uma operação, o Terraform também não vai fazer.

## Próximos passos

- [02_02 - Por que usar o Terraform](02_02-por-que-usar-terraform.md)
- [02_03 - Arquitetura do Terraform](02_03-arquitetura-terraform.md)

## Referências

- [Terraform Introduction](https://developer.hashicorp.com/terraform/intro)
- [HCL Spec](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md)
- [OpenTofu](https://opentofu.org/)
