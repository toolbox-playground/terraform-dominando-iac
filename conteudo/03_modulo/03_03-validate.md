# 03_03 - Validate

## Para que serve

`terraform validate` verifica se a **configuração é válida** — olhando apenas para os arquivos `.tf` e o estado interno do Terraform. Não consulta a nuvem.

```bash
terraform validate
```

Saída esperada em sucesso:

```text
Success! The configuration is valid.
```

Em erro, retorna mensagens apontando linha, arquivo e descrição:

```text
│ Error: Missing required argument
│
│   on main.tf line 3, in resource "aws_s3_bucket" "logs":
│    3:   # bucket = "..."  faltando
│
│ The argument "bucket" is required, but no definition was found.
```

## O que `validate` valida

- **Sintaxe HCL** (chaves, quotes, blocos mal fechados).
- **Referências internas** (`var.xyz` aponta para variável declarada? `aws_instance.foo.bar` existe?).
- **Argumentos obrigatórios** declarados no schema do provider.
- **Tipos** (ex.: passar string onde deveria ser number).
- **Interpolações** mal formadas.
- **Meta-argumentos** (`count`, `for_each`, `depends_on`) sintaticamente corretos.

## O que `validate` **NÃO** valida

- Se o recurso **existe na nuvem** (isso é só no `apply`).
- Se sua AMI/VM realmente existe (usa a API; o validate não).
- Se suas credenciais funcionam.
- Se o nome do bucket S3 está disponível globalmente.
- Se o CIDR conflita com VPC existente.
- Se você tem permissão IAM suficiente.

Ou seja: `validate` é **offline e barato**. Não substitui `plan`.

## Quando rodar

- **Sempre antes de `plan`** — é rápido e pega 80% dos erros triviais.
- **Em pre-commit hook** — impede commit de código com erro óbvio.
- **Em CI**, antes de `plan`, para falhar rápido.
- **Depois de mergear branches** para checar que a fusão não quebrou referências.

## Pré-requisitos

`validate` precisa que `init` já tenha sido executado no diretório, porque ele usa o **schema dos providers** para validar argumentos. Se pular `init`:

```text
│ Error: Could not load plugin
```

Solução: rode `terraform init` primeiro.

### Modo offline (com `-no-tests` e sem providers)

Em alguns pipelines, você quer validar *sem* baixar providers. Use:

```bash
terraform init -backend=false
terraform validate
```

`-backend=false` instala providers mas não configura backend — útil pra CI onde credenciais de backend só existem em outro estágio.

## Exemplos de erros comuns

### 1. Argumento obrigatório faltando

```hcl
resource "aws_s3_bucket" "logs" {}
```

Erro:
```text
The argument "bucket" is required, but no definition was found.
```

### 2. Referência a variável inexistente

```hcl
resource "aws_instance" "web" {
  ami = var.ami_id
  # variable "ami_id" não foi declarada
}
```

Erro:
```text
A variable named "ami_id" has not been declared.
```

### 3. Tipo errado

```hcl
variable "ambiente" {
  type = string
}

resource "aws_s3_bucket" "b" {
  bucket = var.ambiente[0]  # indexa string como lista
}
```

Erro:
```text
This value does not have any indices.
```

### 4. Block name incorreto

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  # provider não tem "root_volume", o correto é "root_block_device"
  root_volume {
    volume_size = 30
  }
}
```

Erro:
```text
Blocks of type "root_volume" are not expected here.
```

### 5. Interpolação com sintaxe antiga

```hcl
resource "aws_instance" "web" {
  ami = "${var.ami_id}"  # funciona, mas fmt remove as "${}" desnecessárias
}
```

`validate` não reclama, mas `fmt` te chama a atenção. Em versões mais novas, a interpolação vira só `var.ami_id`.

## Flags úteis

| Flag | Uso |
|------|-----|
| `-json` | Saída em JSON (útil para integração com ferramentas). |
| `-no-color` | Remove cores (CI). |

Exemplo CI:

```bash
terraform validate -json > validate.json
```

## Como diferir erro de warning

`validate` só imprime **erros** — erros impedem apply. Se você quer dicas mais completas (variáveis não usadas, etc.), use um linter como [**tflint**](https://github.com/terraform-linters/tflint).

## Integração recomendada

### Pre-commit hook

Com [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform):

```yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
```

Todo commit passa por `fmt + validate` antes.

### CI (GitHub Actions, GitLab CI)

Pseudocódigo:

```yaml
steps:
  - checkout
  - setup-terraform:
      terraform_version: 1.7.5
  - run: terraform fmt -check -recursive
  - run: terraform init -backend=false
  - run: terraform validate
  - run: terraform plan -out=plan.tfplan
  - run: terraform show plan.tfplan   # publica na PR
```

## Referências

- [terraform validate](https://developer.hashicorp.com/terraform/cli/commands/validate)
- [tflint](https://github.com/terraform-linters/tflint)
- [pre-commit-terraform](https://github.com/antonbabenko/pre-commit-terraform)
