# 06_07 - Data Sources

Data sources são a porta para **ler informações** do ambiente (AWS, GCP, Azure, Kubernetes…) sem gerenciá-las. Eles são fornecidos pelo **provider** — por isso pertencem a este módulo.

## Diferença entre `resource` e `data`

| Bloco | O que faz | Ciclo de vida |
|-------|-----------|----------------|
| `resource "X" "n"` | **Cria/gerencia** um objeto | CRUD no apply |
| `data "X" "n"` | **Lê** um objeto existente | Só read, no plan/refresh |

Data source não altera nada — ele **consulta**.

## Sintaxe

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

Acesso: `data.<TIPO>.<NOME>.<ATRIBUTO>`.

## Momento de execução

Data sources são avaliados:

- **No `refresh`** (no início de `plan` e `apply`).
- Antes dos recursos que dependem deles.

Se o valor depender de outro recurso ainda não criado, o Terraform adia a resolução para o apply.

## Casos comuns

### 1. Descobrir AMI/imagem mais recente

```hcl
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}
```

### 2. VPC e subnets existentes

```hcl
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

### 3. Identidade/conta atual

```hcl
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
```

### 4. Zona disponível

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "this" {
  count             = 3
  availability_zone = data.aws_availability_zones.available.names[count.index]
  # ...
}
```

### 5. Ler um bucket existente

```hcl
data "aws_s3_bucket" "logs" {
  bucket = "logs-central-2025"
}

output "bucket_region" {
  value = data.aws_s3_bucket.logs.region
}
```

### 6. Consumir outputs de outro state (remote state)

```hcl
data "terraform_remote_state" "rede" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "rede/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.rede.outputs.subnet_public_id
  # ...
}
```

Visto em profundidade no **Módulo 7 - States**.

## Filtros e seleção

Muitos data sources permitem filtrar:

```hcl
data "aws_ami" "nginx" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Application"
    values = ["nginx"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
```

Quando vários resultados são retornados, data sources costumam ter:

- `most_recent = true` (para AMIs).
- `name` (busca exata).
- `filter { ... }` (critérios gerais).
- `tags = { ... }`.

Se **zero** resultados, falha. Se **muitos** e o data source espera um, também falha — você tem que restringir.

## Data sources "genéricos"

Além dos específicos de cada provider, existem:

- **`terraform_remote_state`** — lê outputs de outro state.
- **`http`** — requisição HTTP arbitrária (`hashicorp/http`).
- **`external`** — executa um script e lê o JSON de saída (use com cuidado).
- **`local_file`** — lê conteúdo de arquivo local.
- **`archive_file`** — gera um zip/tar (meio resource, meio data).

```hcl
data "http" "latest_kubernetes" {
  url = "https://dl.k8s.io/release/stable.txt"
}

locals {
  kube_version = trimspace(data.http.latest_kubernetes.response_body)
}
```

## `depends_on` em data sources

Às vezes o data source **precisa** ser resolvido **depois** de um recurso. Exemplo: ler tags de um bucket recém-criado.

```hcl
data "aws_s3_bucket" "logs" {
  bucket = aws_s3_bucket.logs.bucket
  depends_on = [aws_s3_bucket.logs]
}
```

Normalmente o Terraform detecta a dependência pelo uso do atributo, mas há casos em que a ferramenta não pega — daí o `depends_on`.

## Drift e caching

- Data sources **refazem** a leitura a cada `plan`/`refresh` — sempre refletem o estado atual.
- Isso **pode** deixar o plan mais lento em projetos grandes.
- Para mitigar, **evite usar data sources para dados quase-estáticos** — pode ser melhor criar uma `variable` ou um `local`.

## Segurança

Data sources também **chamam a API** — logo, requerem permissão. Conceda mínimo privilégio (`Describe*`, `Get*`, `List*`).

## `terraform console` é útil

Para explorar saídas de data sources:

```bash
terraform console
> data.aws_availability_zones.available.names
[
  "us-east-1a",
  "us-east-1b",
  "us-east-1c",
  "us-east-1d",
  "us-east-1f",
]
```

## Boas práticas

- Use data source para valores **verdadeiramente dinâmicos** (AMIs, contas, zonas).
- Evite criar data source para coisas que mudam a cada dia sem necessidade (provoca drift constante).
- Prefira **outputs de outro state** via `terraform_remote_state` a buscar recursos diretamente na nuvem (fica mais rápido e explícito).
- Documente por que cada data source existe.

## Resumo do módulo

1. Providers são plugins que conectam o Terraform a APIs externas.
2. `required_providers` declara, `provider` configura, `resource` e `data` usam.
3. Versões são fixadas via constraints + lock file.
4. Aliases permitem múltiplas instâncias do mesmo provider.
5. Autenticação deve usar OIDC/roles/SSO — nunca hardcode.
6. Registry público e privado distribuem providers e módulos.
7. Data sources leem estado externo sem gerenciá-lo.

No próximo módulo, **state**: como o Terraform armazena e gerencia o conhecimento da infraestrutura.
