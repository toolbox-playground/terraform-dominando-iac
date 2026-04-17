# Exercício 05 - Renderização com `templatefile`

*(Integra o exercício original 25)*

## Objetivo

Gerar dinamicamente arquivos de configuração a partir de templates.

## Tarefa

1. Criar um arquivo de template `templates/config.tpl`:

   ```ini
   [server]
   name = ${nome}
   port = ${porta}
   env  = ${ambiente}

   [usuarios]
   %{ for u in usuarios ~}
   ${u.nome} = ${u.email}
   %{ endfor ~}
   ```

2. Usar `templatefile` para renderizar esse template com variáveis de input.
3. Expor o resultado renderizado em um output.
4. Também usar o resultado em `user_data` de uma EC2 ou `content` de um `aws_s3_object`.

## Dicas

```hcl
variable "servidor" {
  type = object({
    nome     = string
    porta    = number
    ambiente = string
  })
  default = {
    nome     = "app-01"
    porta    = 8080
    ambiente = "dev"
  }
}

variable "usuarios" {
  type = list(object({
    nome  = string
    email = string
  }))
  default = [
    { nome = "alice", email = "alice@exemplo.com" },
    { nome = "bob",   email = "bob@exemplo.com" },
  ]
}

locals {
  config_renderizada = templatefile("${path.module}/templates/config.tpl", {
    nome      = var.servidor.nome
    porta     = var.servidor.porta
    ambiente  = var.servidor.ambiente
    usuarios  = var.usuarios
  })
}

output "config" {
  value = local.config_renderizada
}

resource "aws_s3_object" "config" {
  bucket  = aws_s3_bucket.app.id
  key     = "config.ini"
  content = local.config_renderizada
}
```

## Verificação

```bash
terraform apply
terraform output config
# [server]
# name = app-01
# port = 8080
# env  = dev
#
# [usuarios]
# alice = alice@exemplo.com
# bob = bob@exemplo.com
```

## Desafio extra

- Adicionar diretiva `%{ if ambiente == "prod" }` ... `%{ endif }` no template para incluir um bloco apenas em produção.
- Gerar um `nginx.conf` real e carregar em `user_data` de uma EC2 com `cloud-init`.
- Comparar `templatefile` com `jsonencode` para um cenário JSON.
