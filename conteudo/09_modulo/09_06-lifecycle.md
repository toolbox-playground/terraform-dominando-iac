# 09_06 - Meta-argumento `lifecycle`

O bloco `lifecycle` ajusta **como** o Terraform cria, atualiza e destrói um recurso. É uma das ferramentas mais poderosas — e mais perigosas — do Terraform.

## Sintaxe

```hcl
resource "aws_instance" "web" {
  # ...

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [tags]
    replace_triggered_by  = [aws_security_group.web.id]

    precondition {
      condition     = var.ambiente != "prod" || var.ha
      error_message = "Prod exige HA."
    }

    postcondition {
      condition     = self.public_ip != ""
      error_message = "Instância precisa ter IP público."
    }
  }
}
```

## `create_before_destroy`

Padrão: `false` (destrói antes de criar novo).

Com `true`: cria primeiro, depois destrói antigo. Essencial para:

- **Zero downtime**.
- **Infraestrutura imutável**: gerar nova AMI → nova instância → swap → desligar antiga.

```hcl
lifecycle {
  create_before_destroy = true
}
```

**Cuidado**: algumas propriedades exigem unicidade (ex.: `name` de ASG, nome de bucket). Nesses casos, use nomes únicos (`random_id`, `timestamp`) ou `name_prefix`.

## `prevent_destroy`

Bloqueia destruição do recurso. Útil para:

- Bancos de dados de produção.
- Buckets com dados críticos.
- Recursos "caros demais para recriar".

```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

Efeito: se você tentar `terraform destroy` ou remover do código, Terraform para com erro.

Para destruir de verdade, remova o `prevent_destroy` e rode novamente.

## `ignore_changes`

Diz ao Terraform para **ignorar mudanças** em certos atributos. Útil quando:

- Atributo é gerenciado por outra ferramenta (ex.: autoscaling altera `desired_capacity`).
- Valor muda externamente por design (ex.: `tags` adicionadas por sistemas externos).

```hcl
lifecycle {
  ignore_changes = [
    tags["AutoSchedule"],
    desired_capacity,
  ]
}
```

Para ignorar **tudo**:

```hcl
lifecycle {
  ignore_changes = all
}
```

Muito raro querer isso.

## `replace_triggered_by`

Força recriação quando **outro** recurso muda. Ex.: usar timestamp ou hash de configuração:

```hcl
resource "aws_instance" "web" {
  user_data = templatefile("${path.module}/user-data.sh", { ... })

  lifecycle {
    replace_triggered_by = [null_resource.user_data_hash]
  }
}

resource "null_resource" "user_data_hash" {
  triggers = {
    hash = sha256(file("${path.module}/user-data.sh"))
  }
}
```

Quando o arquivo muda → `null_resource` muda → força recriar a instância.

## `precondition` e `postcondition`

Validam invariantes antes (`precondition`) ou depois (`postcondition`) do apply.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    precondition {
      condition     = data.aws_ami.ubuntu.architecture == "x86_64"
      error_message = "AMI precisa ser x86_64."
    }

    postcondition {
      condition     = self.public_ip != ""
      error_message = "Instância criada sem IP público."
    }
  }
}
```

`self` referencia o **recurso recém-criado**.

## Ordem de aplicação

Quando `create_before_destroy = true`:

```mermaid
flowchart LR
  A[Recurso antigo existe] --> B[Criar novo recurso]
  B --> C[Atualizar referências]
  C --> D[Destruir recurso antigo]
```

Sem `create_before_destroy`:

```mermaid
flowchart LR
  A[Destruir antigo] --> B[Criar novo]
```

## `prevent_destroy` com recursos em listas (`count`/`for_each`)

```hcl
resource "aws_s3_bucket" "db" {
  for_each = toset(var.dbs)
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

Aplicável a todos os elementos do `for_each`. Remover um item do `var.dbs` falha → você precisa antes remover o `prevent_destroy`.

## Anti-patterns

- **Abusar de `ignore_changes`**: esconder drift real mascara problemas.
- **`prevent_destroy` em tudo**: impede refatorações.
- **`create_before_destroy` sem pensar em nomes únicos**: recriação falha.
- **`replace_triggered_by` com valor volátil** (ex.: `timestamp()` sempre muda): recria a cada apply.

## Exemplo real: ASG com create_before_destroy

```hcl
resource "aws_launch_template" "web" {
  name_prefix   = "web-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix         = "web-asg-"
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = var.subnet_ids

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

Atualização do launch template → create_before_destroy cria novo ASG → velho é destruído → zero downtime (se ALB distribuir tráfego entre os dois temporariamente).

## Check de `lifecycle` com `check` blocks (1.5+)

Para validações cross-resource, use o bloco `check`:

```hcl
check "asg_tamanho" {
  assert {
    condition     = aws_autoscaling_group.web.desired_capacity >= var.min_size
    error_message = "ASG abaixo do mínimo."
  }
}
```

Avaliado após apply; útil em CI.

## Boas práticas

- Use `create_before_destroy` em recursos críticos para disponibilidade.
- Use `prevent_destroy` em recursos com dados (DBs, buckets).
- Use `ignore_changes` **cirurgicamente**, documentando por quê.
- Use `precondition`/`postcondition` para detectar problemas cedo.
- **Leia a doc** do recurso — alguns têm comportamentos especiais com lifecycle.

Próximo tópico: **templates e arquivos externos**.
