# 05_07 - JSON como Alternativa ao HCL

Terraform suporta **dois formatos equivalentes** para arquivos de configuração:

- **`.tf`** — HCL (humanamente amigável).
- **`.tf.json`** — JSON (amigável para máquinas).

Ambos produzem a mesma configuração depois de parseados. Terraform lê e entende os dois; você pode até misturá-los no mesmo diretório.

## Quando usar JSON?

JSON é **raro** em projetos escritos à mão — HCL é mais confortável. Use JSON quando:

- **Geração programática**: outra ferramenta gera Terraform (ex.: CDK for Terraform, scripts internos).
- **Integração com APIs**: você consome dados estruturados e converte.
- **Template engines** que emitem JSON nativamente.
- **Ferramentas de import** ou conversores (`terraformer`, `hcl2tojson`).

Se você escreve à mão, **continue com HCL**. Este tópico é informativo.

## Regras de conversão

### Bloco

HCL:

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "logs-2026"
}
```

JSON equivalente (`main.tf.json`):

```json
{
  "resource": {
    "aws_s3_bucket": {
      "logs": {
        "bucket": "logs-2026"
      }
    }
  }
}
```

Regras:

- O tipo de bloco vira **chave** do objeto raiz.
- Labels viram **aninhamentos sucessivos**.
- O corpo do bloco vira o **objeto mais interno**.

### Múltiplos blocos do mesmo tipo

HCL:

```hcl
resource "aws_s3_bucket" "logs" { ... }
resource "aws_s3_bucket" "dados" { ... }
```

JSON:

```json
{
  "resource": {
    "aws_s3_bucket": {
      "logs":  { ... },
      "dados": { ... }
    }
  }
}
```

### Sub-blocos repetidos

Em HCL, você pode ter vários `statement { ... }` em uma policy. Em JSON, vira um **array de objetos**:

HCL:

```hcl
resource "null_resource" "x" {
  triggers { a = "1" }
  triggers { b = "2" }
}
```

JSON:

```json
{
  "resource": {
    "null_resource": {
      "x": {
        "triggers": [
          { "a": "1" },
          { "b": "2" }
        ]
      }
    }
  }
}
```

### Interpolações

As expressões `${...}` são preservadas dentro de strings JSON:

```json
{
  "resource": {
    "aws_instance": {
      "web": {
        "ami":  "${data.aws_ami.ubuntu.id}",
        "tags": { "Env": "${var.ambiente}" }
      }
    }
  }
}
```

### Comentários

JSON **não permite comentários**. Esta é uma das maiores razões para preferir HCL ao escrever à mão.

Se precisar de notas em um arquivo JSON, você pode abusar de uma chave `_comment`:

```json
{ "_comment": "gerado automaticamente por tool X", "resource": { ... } }
```

Mas isso é feio e não idiomático.

## Exemplo completo

HCL:

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

variable "ambiente" {
  type    = string
  default = "dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "logs-${var.ambiente}"

  tags = {
    Env = var.ambiente
  }
}
```

JSON equivalente (`main.tf.json`):

```json
{
  "terraform": {
    "required_version": ">= 1.5",
    "required_providers": {
      "aws": {
        "source":  "hashicorp/aws",
        "version": "~> 5.0"
      }
    }
  },
  "provider": {
    "aws": {
      "region": "us-east-1"
    }
  },
  "variable": {
    "ambiente": {
      "type":    "string",
      "default": "dev"
    }
  },
  "resource": {
    "aws_s3_bucket": {
      "logs": {
        "bucket": "logs-${var.ambiente}",
        "tags": {
          "Env": "${var.ambiente}"
        }
      }
    }
  }
}
```

## Limitações em JSON

JSON perde algumas facilidades do HCL:

- **Sem heredoc** — strings multilinha viram `\n` literal, menos legíveis.
- **Sem diretivas `%{ if }` / `%{ for }`** — ainda funcionam se embutidas como string, mas o JSON em si não tem estrutura para isso.
- **Tipos complexos viram aninhamentos de objetos** — mais verboso.
- **Sem comentários**.

## Conversão na prática

- **HCL → JSON**: use `hcl2json` (ferramenta externa) ou `terraform show -json plan`.
- **JSON → HCL**: `hcl2tojson` e similares, mas raramente necessário.

Dentro do Terraform:

```bash
# Ver o plan em JSON (para pipelines analisarem)
terraform show -json planfile > plan.json
```

Isso produz um JSON com o **resultado** do plan, não com a configuração.

## Resumo

- JSON é **suporte secundário** do Terraform, destinado a ferramentas.
- Se você escreve à mão, **use HCL** — sempre.
- Entender o mapeamento ajuda quando você depura tooling, gera código ou converte projetos.

Próximo tópico: **exemplo completo comentado**, juntando tudo deste módulo.
