# 05_06 - Strings e Templating

Strings em HCL vão de simples literais a templates com condicionais e loops. Esta é a base para configurar nomes, user-data de EC2, políticas IAM, scripts cloud-init e arquivos de configuração.

## Tipos de strings

### 1. String simples

```hcl
regiao = "us-east-1"
```

Sem interpolação. `\n`, `\t`, `\u0041` e outros escapes funcionam.

### 2. String com interpolação

Com `${...}` dentro de aspas duplas:

```hcl
bucket = "logs-${var.ambiente}-${var.time}"
```

Qualquer expressão válida pode aparecer dentro:

```hcl
tags = {
  Name = "${upper(var.nome)}-${var.ambiente == "prod" ? "PRD" : "DEV"}"
}
```

### 3. Heredoc

Para strings multilinha:

```hcl
politica = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [...]
}
EOT
```

Variação com `<<-` remove indentação comum:

```hcl
script = <<-EOT
  #!/bin/bash
  apt-get update
  apt-get install -y ${var.pacote}
EOT
```

Sem o `-`, a indentação precisa começar na coluna 0.

Identificador arbitrário: pode ser qualquer palavra (`EOT`, `SCRIPT`, `JSON`).

## Sequências de escape

| Escape | Significado |
|--------|-------------|
| `\n` | nova linha |
| `\t` | tab |
| `\\` | barra invertida |
| `\"` | aspas duplas |
| `\u0041` | caractere Unicode |
| `$${` | `${` literal (escape de interpolação) |
| `%%{` | `%{` literal (escape de diretiva) |

```hcl
mensagem = "Preço: R$ 100 e $${var.taxa}%"
# Resulta em: Preço: R$ 100 e ${var.taxa}%
```

## Diretivas de template

Além de `${...}` (expressão), HCL suporta `%{...}` (diretiva de fluxo de controle).

### Condicional

```hcl
saudacao = "Olá %{ if var.formal }senhor%{ else }fera%{ endif }!"
```

Multilinha:

```hcl
config = <<-EOT
  log_level = "info"
  %{ if var.debug ~}
  debug = true
  %{ endif ~}
EOT
```

O `~` no final/começo do delimitador **remove espaços em branco** ao redor (inclusive newline).

### Loop

```hcl
hosts = <<-EOT
  %{ for h in var.hosts ~}
  ${h.nome}: ${h.ip}
  %{ endfor ~}
EOT
```

Exemplo de saída:

```
web1: 10.0.1.10
web2: 10.0.1.11
web3: 10.0.1.12
```

## Funções de string úteis

| Função | Exemplo | Resultado |
|--------|---------|-----------|
| `upper` | `upper("oi")` | `"OI"` |
| `lower` | `lower("OI")` | `"oi"` |
| `title` | `title("um titulo")` | `"Um Titulo"` |
| `trim` | `trim("  oi  ", " ")` | `"oi"` |
| `trimspace` | `trimspace("\toi\n")` | `"oi"` |
| `replace` | `replace("a-b", "-", "_")` | `"a_b"` |
| `regex` | `regex("[a-z]+", "ola123")` | `"ola"` |
| `regexall` | `regexall("\\d+", "a1b2")` | `["1","2"]` |
| `format` | `format("%s-%02d", "web", 3)` | `"web-03"` |
| `formatlist` | `formatlist("%s.txt", ["a","b"])` | `["a.txt","b.txt"]` |
| `split` | `split(",", "a,b,c")` | `["a","b","c"]` |
| `join` | `join("-", ["a","b"])` | `"a-b"` |
| `substr` | `substr("hashicorp", 0, 4)` | `"hash"` |
| `startswith` | `startswith("arn:aws", "arn:")` | `true` |
| `endswith` | `endswith("file.txt", ".txt")` | `true` |
| `length` | `length("texto")` | `5` |

## `templatefile` - arquivos externos

Quando o template é grande (user-data, manifesto k8s, config de app), separe em arquivo e use `templatefile`:

Arquivo `templates/user-data.tpl`:

```bash
#!/bin/bash
set -e
apt-get update
apt-get install -y ${pacote}
echo "Host: ${hostname}" > /etc/motd
```

Uso:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  user_data = templatefile("${path.module}/templates/user-data.tpl", {
    pacote   = "nginx"
    hostname = "web-${var.ambiente}"
  })
}
```

Vantagens:

- Sintaxe destacada no editor (`.tpl` pode ser tratado como bash/HTML/JSON).
- Testável isoladamente.
- Reaproveitável entre recursos.

## `jsonencode` e `yamlencode`

Para strings JSON/YAML **estruturadas**, **não** concatene à mão — use funções dedicadas:

```hcl
resource "aws_iam_role_policy" "s3" {
  name = "s3-access"
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.dados.arn}/*"
      }
    ]
  })
}
```

Isso:

- Evita erros de aspas/vírgulas.
- Usa HCL para lógica (ternários, `for`).
- Fácil de refatorar.

Mesma ideia para YAML (`yamlencode`) em manifestos Kubernetes.

## Normalização e comparação

Strings são comparadas byte a byte. Cuidado com:

- Espaços no fim (use `trimspace`).
- Caixa diferente (use `lower()` / `upper()`).
- Encoding (sempre UTF-8).

## Exemplo completo

```hcl
locals {
  app = "billing"
  env = var.ambiente

  nome_base     = lower("${local.app}-${local.env}")
  nome_bucket   = "${local.nome_base}-logs-${random_id.suffix.hex}"
  nome_iam_role = format("%s-%s-role", local.app, local.env)

  tags_padrao = {
    Application = local.app
    Environment = local.env
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = local.nome_bucket
  tags   = local.tags_padrao
}

resource "aws_iam_role" "app" {
  name = local.nome_iam_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.tags_padrao
}
```

## Boas práticas

- **Use `templatefile`** para scripts e configs longas.
- **Use `jsonencode`/`yamlencode`** em vez de heredoc para dados estruturados.
- **Prefira `locals`** para nomes e formatações reutilizáveis.
- **Cuide de escape**: `$${` e `%%{` quando quiser literal.
- **Teste com `terraform console`**: valida formatação rapidamente.

Próximo tópico: **JSON como alternativa ao HCL**.
