# 04_02 - Dependências Implícitas

## O que são

Quando um recurso **referencia um atributo de outro recurso**, o Terraform automaticamente entende que existe uma **dependência**. Não é preciso declarar nada — o grafo é construído a partir dessas referências.

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id   # <-- referência
  cidr_block = "10.0.1.0/24"
}
```

Aqui, `aws_subnet.public` depende implicitamente de `aws_vpc.main`. O Terraform:

- Cria a VPC **antes** da subnet.
- Destrói a subnet **antes** da VPC.
- Ignora paralelismo entre os dois.

## Como o Terraform descobre

Ele parseia o código e procura por **referências** no formato `TIPO.NOME.ATRIBUTO`:

- `aws_vpc.main.id`
- `aws_db_instance.example.endpoint`
- `data.aws_ami.ubuntu.id`
- `var.nome`
- `module.vpc.vpc_id`

Cada referência vira uma aresta no grafo de dependências.

## Visualizando o grafo

```bash
terraform graph | dot -Tsvg > graph.svg
```

Abre um SVG mostrando o DAG (Directed Acyclic Graph) de recursos.

## Por que prefira dependências implícitas

- **Automáticas** — sem esquecer de declarar.
- **Corretas por construção** — a referência é a evidência da dependência.
- **Autoexplicativas** — o código mostra quem depende de quem.
- **Refactoring-friendly** — se a referência muda, a dependência segue junto.

## Quando a dependência implícita é suficiente

**Caso 1: VPC → Subnet → Instância**

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_instance" "web" {
  subnet_id     = aws_subnet.public.id
  ami           = "ami-0123"
  instance_type = "t3.micro"
}
```

O Terraform cria na ordem: VPC → subnet → instância. Destruição na ordem inversa.

**Caso 2: Security group na VPC**

```hcl
resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

A referência `aws_vpc.main.id` já é suficiente.

**Caso 3: App dependendo do DB**

```hcl
resource "aws_db_instance" "main" {
  identifier     = "minha-db"
  engine         = "postgres"
  # ...
}

resource "aws_instance" "app" {
  ami           = "ami-0123"
  instance_type = "t3.small"

  user_data = <<-EOF
    #!/bin/bash
    echo "DB_HOST=${aws_db_instance.main.endpoint}" > /etc/app.conf
  EOF
}
```

O `user_data` **referencia** o endpoint do DB → o Terraform cria o DB primeiro.

## Limitações

Dependências implícitas não capturam relações **semânticas** que não passam por atributo:

- "Crie a IAM role antes, porque minha aplicação assume essa role ao iniciar, mesmo sem o Terraform saber disso."
- "Este bucket precisa da policy do IAM antes de ser usado."

Nesses casos você precisa de **dependência explícita** (`depends_on`) — ver [04_03](04_03-dependencias-explicitas.md).

## Dicas

### Prefira atributos úteis

Às vezes há duas formas de referenciar:

```hcl
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id   # estabelece dependência
}
```

vs.

```hcl
resource "aws_subnet" "public" {
  vpc_id = "vpc-123456"      # valor hardcoded, sem dependência!
}
```

O segundo exemplo **perde** a dependência. O Terraform não sabe que a subnet precisa da VPC. Pode tentar criar em paralelo e falhar.

### Exemplo de bug clássico

```hcl
resource "aws_iam_role" "app" { ... }

resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = "app"              # string literal
  policy_arn = aws_iam_policy.app.arn
}
```

Isso **não** cria dependência entre `aws_iam_role_policy_attachment` e `aws_iam_role`. Se a role ainda não foi criada, o attachment falha.

Correto:

```hcl
resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = aws_iam_role.app.name  # referência real
  policy_arn = aws_iam_policy.app.arn
}
```

### Desconfie de `count` ou `for_each` sem referência

```hcl
resource "aws_subnet" "public" {
  count      = 3
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.${count.index}.0/24"
}

resource "aws_instance" "web" {
  count     = 3
  subnet_id = aws_subnet.public[count.index].id  # boa prática
}
```

A referência `aws_subnet.public[count.index].id` preserva a dependência mesmo em recursos múltiplos.

## Resumo

- **Dependência implícita** = referência via atributo (`recurso.nome.atributo`).
- **O Terraform faz sozinho** — não declare se já tem a referência.
- **Sempre prefira** dependência implícita em cima de explícita.

## Referências

- [Resource Dependencies](https://developer.hashicorp.com/terraform/tutorials/configuration-language/dependencies)
- [terraform graph](https://developer.hashicorp.com/terraform/cli/commands/graph)
