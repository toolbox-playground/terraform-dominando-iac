# 05_01 - O que é HCL

## Definição

**HCL** (HashiCorp Configuration Language) é a linguagem declarativa criada pela HashiCorp para descrever configurações de forma **legível por humanos e interpretável por máquinas**. É usada em Terraform, Vault, Consul, Nomad, Packer e Waypoint.

HCL foi projetada com três objetivos em mente:

1. **Legibilidade**: um engenheiro que nunca viu o código deve conseguir entender em poucos minutos.
2. **Expressividade**: deve permitir lógica razoavelmente complexa (interpolações, loops, condicionais).
3. **Ferramentabilidade**: deve ser fácil para ferramentas parsearem, modificarem e gerarem.

## Por que não JSON puro?

JSON é ótimo para troca entre máquinas, mas péssimo para humanos escreverem:

- Sem comentários.
- Muitas chaves/colchetes.
- Indentação exigente.
- Sem templates nativos.

```json
{
  "resource": {
    "aws_s3_bucket": {
      "logs": {
        "bucket": "logs-2026",
        "tags": {
          "Env": "prod"
        }
      }
    }
  }
}
```

HCL equivalente:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "logs-2026"

  tags = {
    Env = "prod"
  }
}
```

Mais curto, mais claro, com comentários permitidos.

## Ecossistema HCL

- **HCL 1** (usado em Terraform 0.11) — mais simples, com limitações.
- **HCL 2** (Terraform 0.12+, atual) — suporte a tipos, expressões ricas, funções.
- **HCL JSON variant** — todo arquivo `.tf` pode ser escrito como `.tf.json` — útil para geração programática.

Este curso assume HCL 2.

## Anatomia de um arquivo HCL

Um arquivo HCL é composto de **blocos** (blocks) e **atributos** (arguments).

```hcl
block_type "label1" "label2" {
  argument_a = value
  argument_b = value

  nested_block {
    argument = value
  }
}
```

Exemplo no Terraform:

```hcl
resource "aws_instance" "web" {   # bloco com dois labels: tipo e nome
  ami           = "ami-0123"       # atributo
  instance_type = "t3.micro"       # atributo

  root_block_device {              # bloco aninhado
    volume_size = 30
  }
}
```

## Elementos principais

### Blocos

Definem objetos da configuração. Em Terraform:

- `terraform { ... }`
- `provider "aws" { ... }`
- `resource "tipo" "nome" { ... }`
- `data "tipo" "nome" { ... }`
- `variable "nome" { ... }`
- `output "nome" { ... }`
- `locals { ... }`
- `module "nome" { ... }`

### Atributos

Pares `chave = valor`:

```hcl
bucket = "logs-2026"
count  = 3
tags = {
  Env = "prod"
}
```

### Comentários

```hcl
# Comentário de uma linha
// Outro comentário de uma linha

/*
  Comentário de
  múltiplas linhas
*/
```

### Identificadores

- Começam com letra, seguidos de letras, dígitos, `_` ou `-`.
- Case-sensitive.
- Convenção: `snake_case`.

### Strings

```hcl
nome       = "web"
mensagem   = "Ola, ${var.nome}!"       # interpolação
multilinha = <<-EOT
  Primeira linha
  Segunda linha
EOT
```

## HCL vs. Terraform

HCL é a **linguagem**. Terraform é **um dos usuários** dela, com:

- Vocabulário próprio (blocos `resource`, `data`, `variable`, etc.).
- Expressões específicas (`aws_instance.web.id`).
- Funções built-in do Terraform (`cidrsubnet`, `jsondecode`, etc.).

Outras ferramentas HashiCorp usam HCL com vocabulário próprio. Ou seja: **aprender HCL é um investimento** que serve para vários produtos.

## Validadores e editores

- **`terraform fmt`** — formatador oficial.
- **`terraform validate`** — valida código Terraform (não HCL genérico).
- **VS Code** + extensão HashiCorp Terraform.
- **IntelliJ IDEA** + plugin HashiCorp.
- **vim/neovim** com plugins.

## O que vem por aí

Nos próximos tópicos deste módulo, cobrimos:

- Sintaxe básica (blocos, atributos, comentários).
- Tipos primitivos e complexos.
- Operadores e expressões.
- Strings e heredoc.
- JSON como alternativa.
- Exemplo completo comentado.

Depois, no **Módulo 9**, vemos o HCL avançado: `count`, `for_each`, expressões `for`, splat, dynamic blocks, `lifecycle`, templates e funções built-in.

## Referências

- [HCL Syntax Specification](https://github.com/hashicorp/hcl/blob/main/hclsyntax/spec.md)
- [Terraform Language Overview](https://developer.hashicorp.com/terraform/language)
