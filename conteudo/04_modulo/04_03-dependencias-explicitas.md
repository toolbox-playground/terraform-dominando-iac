# 04_03 - Dependências Explícitas

## O que são

Quando não há uma referência natural entre dois recursos, mas você sabe que **um precisa ser criado antes do outro**, use o meta-argumento `depends_on`:

```hcl
resource "aws_iam_role" "app" {
  name = "app-role"
  # ...
}

resource "aws_instance" "app" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  depends_on = [aws_iam_role.app]
}
```

## Quando usar

**Use `depends_on` quando a dependência não aparece em atributo**, mas existe semanticamente. Exemplos:

### 1. IAM policy com aplicação que a usa implicitamente

A aplicação que roda na EC2 assume uma role. O Terraform não sabe disso olhando só o `ami`. Você diz:

```hcl
resource "aws_instance" "app" {
  ami           = "ami-0123"
  instance_type = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.app.name

  user_data = <<-EOF
    #!/bin/bash
    # aplicação que assume a role para acessar S3
  EOF

  # policy attachment precisa existir antes de a instância rodar user_data
  depends_on = [aws_iam_role_policy_attachment.app_s3]
}
```

### 2. Database precisa existir antes do app (com user_data que não referencia)

Se o `user_data` não referencia o DB diretamente mas, semanticamente, o app só funciona com DB pronto:

```hcl
resource "aws_db_instance" "main" { ... }

resource "aws_instance" "app" {
  # ...
  depends_on = [aws_db_instance.main]
}
```

Note: **sempre prefira referenciar via atributo** (`user_data` lendo o endpoint do DB). `depends_on` é fallback quando a referência não existe.

### 3. Security group rules ordem

Certas ordens de regras de SG precisam ser respeitadas em cenários específicos.

### 4. Bucket S3 com policy necessária

Uma Lambda que escreve em bucket precisa que a bucket policy exista antes da função começar a tentar escrever.

## Como funciona

Terraform:

1. Adiciona aresta `B depends on A` no grafo.
2. Cria A antes de B.
3. Destrói B antes de A.

Exatamente como dependência implícita — mas declarado manualmente.

## Sintaxe

```hcl
depends_on = [
  aws_iam_role.app,
  aws_iam_policy.app,
  aws_vpc.main,
]
```

**Lista de endereços de recursos**, sem `.id` ou `.arn`. Terraform só precisa saber quem, não qual atributo.

## Exemplo completo

```hcl
resource "aws_db_instance" "example" {
  engine         = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  username       = "admin"
  password       = var.db_password
  skip_final_snapshot = true
}

resource "aws_instance" "app_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  user_data = <<-EOF
    #!/bin/bash
    echo "Configurando aplicacao..."
  EOF

  depends_on = [aws_db_instance.example]
}

resource "aws_security_group" "allow_traffic" {
  name        = "allow_specific_traffic"
  description = "Permite trafego especifico"
  vpc_id      = aws_vpc.main.id

  depends_on = [aws_vpc.main]
}
```

Note que no segundo `depends_on` (security group) o `vpc_id = aws_vpc.main.id` **já cria dependência implícita**. O `depends_on` aqui é **redundante** e deve ser removido. Isso ilustra um erro comum.

## Quando NÃO usar

- **Já existe referência implícita**: é redundante e confunde quem lê o código.
- **Para "garantir ordem" sem entender por quê**: sinal vermelho — investigue a causa real.
- **Workaround para falha de API**: melhor reportar bug no provider.

## Custos

`depends_on` **desabilita paralelismo**. Se você colocar vários recursos dependendo do mesmo, eles rodam sequencialmente. Isso pode **deixar o apply mais lento**.

## Versões modernas

No Terraform moderno (>= 1.3), você pode usar `depends_on` também em:

- `module` blocks — "este módulo só roda depois daquele".
- `data` sources — útil quando um `data` depende de um recurso recém-criado.

```hcl
module "app" {
  source = "./modules/app"
  depends_on = [module.vpc]
}

data "aws_iam_role" "app" {
  name       = "app-role"
  depends_on = [aws_iam_role.app]  # garante role já criada
}
```

## Resumo

- **Dependência implícita > explícita**. Sempre.
- Use `depends_on` **só quando** a ligação semântica não passa por atributo.
- **Nunca use** como muleta para esconder problema de design.
- `depends_on` afeta ordem de **criação e destruição**.

## Referências

- [The depends_on Meta-Argument](https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on)
- [04_02 - Dependências Implícitas](04_02-dependencias-implicitas.md)
