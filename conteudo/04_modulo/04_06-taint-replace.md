# 04_06 - Taint, Untaint e `-replace`

## Problema

Às vezes um recurso está "quebrado" na nuvem (VM corrompida, container com bug de inicialização, storage com configuração inconsistente) mas **o Terraform acha que está tudo certo**. Você quer **forçar a substituição** na próxima execução.

Historicamente, isso era feito com `terraform taint`. Desde o Terraform **0.15.2**, esse comando está **depreciado** em favor da flag `-replace` do `plan`/`apply`.

## `terraform taint` (depreciado)

### Como era usado

```bash
terraform taint aws_instance.web
```

Isso marcava o recurso como "tainted" no state. No próximo `apply`, o Terraform destruía e recriava.

```bash
terraform untaint aws_instance.web
```

Desmarcava (caso tivesse sido marcado por engano).

### Por que foi depreciado

- **Mutava o state diretamente** — criava situações difíceis de debugar.
- **Não aparecia no plan**, só aparecia no apply — surpresa ruim.
- **Não era versionado** — você marcava no seu terminal, ninguém mais via.
- **Em time, causava conflitos** — duas pessoas taint-ando o mesmo recurso.

### Quando ainda aparece

- Códigos legados pode ter workflows dependentes de taint.
- Em scripts antigos, mas devem ser migrados.

## `-replace` (moderno)

Desde 0.15.2, a forma correta é usar o flag `-replace`:

```bash
terraform plan -replace="aws_instance.web"
terraform apply -replace="aws_instance.web"
```

### Vantagens

- **Aparece no plan**: `-/+` com o recurso marcado para replace.
- **Não muda state antes de aplicar**: se cancelar, nada foi feito.
- **Explícito e pontual**: cada execução declara o que quer substituir.
- **Funciona em CI/CD**: fica em linha de comando, versionável.

### Exemplo

```bash
terraform apply -replace="aws_instance.web"
```

Saída do plan:
```text
  # aws_instance.web will be replaced, as requested
-/+ resource "aws_instance" "web" {
      ~ id            = "i-0abc123" -> (known after apply)
      # ...
    }

Plan: 1 to add, 0 to change, 1 to destroy.
```

### Múltiplos recursos

```bash
terraform apply -replace="aws_instance.web" -replace="aws_instance.api"
```

### Com count/for_each

```bash
terraform apply -replace='aws_instance.web[0]'
terraform apply -replace='aws_instance.web["us-east-1a"]'
```

## Quando usar `-replace`

- **Recurso corrompido** que não dá pra consertar via API.
- **Bug de provisioner** que deixou VM em estado inconsistente.
- **Atualização de AMI via lookup dinâmico** quando provider não faz replace automático.
- **Reciclagem periódica** para renovar servidores (em vez de patching in-place).

## Quando NÃO usar

- **Para resolver drift**: use `apply` normal, que corrige o drift.
- **Para forçar update em atributo que deveria ser mutável**: abra issue no provider.
- **Para "reiniciar" um recurso**: normalmente a API tem restart; replace é mais destrutivo.

## Alternativas modernas

### `lifecycle { replace_triggered_by }`

Em 1.2+, você pode declarar no código que um recurso deve ser recriado quando outro muda:

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.latest.id
  instance_type = "t3.micro"

  lifecycle {
    replace_triggered_by = [
      null_resource.deploy_trigger
    ]
  }
}

resource "null_resource" "deploy_trigger" {
  triggers = {
    deploy_timestamp = var.deploy_timestamp
  }
}
```

Toda vez que `deploy_timestamp` muda, a instância é recriada — sem CLI manual.

### `create_before_destroy`

Para replace sem downtime:

```hcl
resource "aws_instance" "web" {
  # ...
  lifecycle {
    create_before_destroy = true
  }
}
```

O Terraform cria a nova antes de destruir a antiga.

## Resumo

| Técnica | Quando usar |
|---------|-------------|
| `terraform taint` | **Não use mais** (depreciado) |
| `terraform apply -replace` | Força replace pontual em CLI |
| `lifecycle.replace_triggered_by` | Replace automático baseado em outra mudança |
| `lifecycle.create_before_destroy` | Replace sem downtime |

## Referências

- [Terraform Taint Deprecation](https://developer.hashicorp.com/terraform/cli/commands/taint)
- [-replace flag](https://developer.hashicorp.com/terraform/cli/commands/plan#replace-address)
- [lifecycle replace_triggered_by](https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#replace_triggered_by)
