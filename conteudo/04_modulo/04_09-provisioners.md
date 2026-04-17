# 04_09 - Provisioners

## O que são

**Provisioners** são blocos dentro de um `resource` que executam **comandos shell ou uploads de arquivo** quando um recurso é criado ou destruído. Eles permitem:

- Rodar scripts em VMs recém-criadas.
- Executar comandos locais após provisionar.
- Copiar arquivos para o host remoto.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }
}
```

## A grande verdade: **EVITE provisioners**

A HashiCorp mesma, em sua documentação, diz:

> "**Provisioners are a last resort.**"

Por quê?

1. **Não são idempotentes** (por padrão) — rodar um script shell duas vezes pode dar resultado diferente.
2. **Só rodam na criação** do recurso — mudar o script e rodar apply não executa de novo.
3. **Quebram o grafo do Terraform** — se o script falha, o recurso fica em estado parcial.
4. **Não fazem parte do plan** — você não sabe "o que vai rodar" até rodar.
5. **Acoplam lógica imperativa** ao código declarativo.
6. **Dependem de conectividade** — SSH, WinRM, permissões.

## Tipos de provisioners

### `local-exec`

Roda um comando na **máquina onde o Terraform está rodando**.

```hcl
resource "aws_instance" "web" {
  # ...
  provisioner "local-exec" {
    command = "echo ${self.public_ip} >> ips.txt"
  }
}
```

Casos típicos (ainda questionáveis):
- Acionar webhook após provisionar.
- Invalidar cache DNS.
- Disparar pipeline de configuração externa.

### `remote-exec`

Roda comando **dentro do recurso remoto** (via SSH/WinRM).

```hcl
provisioner "remote-exec" {
  inline = [
    "sudo apt-get update",
    "sudo apt-get install -y nginx",
  ]
}
```

Ou via script:

```hcl
provisioner "remote-exec" {
  script = "scripts/setup.sh"
}
```

### `file`

Copia arquivo/diretório para o recurso.

```hcl
provisioner "file" {
  source      = "scripts/setup.sh"
  destination = "/tmp/setup.sh"
}
```

## Ordem dos provisioners

Executam em ordem de aparição no bloco:

```hcl
resource "aws_instance" "web" {
  provisioner "file" { ... }
  provisioner "remote-exec" {
    inline = ["sh /tmp/setup.sh"]
  }
}
```

## Provisioners de destroy

Existem `when = destroy`:

```hcl
provisioner "local-exec" {
  when    = destroy
  command = "echo 'destroying ${self.id}' >> audit.log"
}
```

Roda **antes** da destruição do recurso. Uso: backup, desregistrar de monitor, etc.

**Limitação**: referências dentro do bloco devem ser **`self`** ou constantes — não pode referenciar outros recursos (por design, evitando ciclos).

## Bloco `connection`

Define como conectar no recurso (para `remote-exec` e `file`):

```hcl
connection {
  type        = "ssh"
  user        = "ubuntu"
  private_key = file("~/.ssh/id_rsa")
  host        = self.public_ip
  timeout     = "5m"
}
```

Pode ser colocado dentro do provisioner ou do `resource` (compartilhado).

## Por que evitar — alternativas

### AMIs/Imagens pré-buildadas (Packer)

Em vez de `remote-exec` pra instalar pacotes:

1. **Packer** builda AMI com tudo instalado.
2. Terraform **usa a AMI**.

Vantagens:
- Imutável.
- Builds testáveis e versionados.
- Deploy em minutos (não precisa rodar apt).

### `user_data` (cloud-init)

Praticamente todas as nuvens aceitam `user_data` — script executado na **primeira inicialização da VM** pela própria cloud.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0123"
  instance_type = "t3.micro"

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
  EOF
}
```

Vantagens:
- Parte do recurso, não de provisioner.
- Se mudar o `user_data`, o recurso é recriado (imutável).
- Não precisa SSH aberto do Terraform pra fora.

### Ansible/Chef/Puppet depois

- Terraform cria a máquina.
- Ansible configura.
- Cada ferramenta faz o que é boa.

### SSM Run Command (AWS)

Rodar comandos via SSM (sem SSH) é mais seguro e automatizável.

## Quando provisioners são realmente a solução

Situações raras:

- **Desenvolvimento/laboratório** onde você só precisa que algo rode uma vez.
- **Operação externa** que só o Terraform pode disparar (ex.: registrar host em DNS externo legado).
- **Bootstrap** de cluster que não aceita nada além de SSH.

Mesmo nesses casos, considere alternativas antes.

## `null_resource` com provisioner

Padrão comum para rodar algo desacoplado:

```hcl
resource "null_resource" "migrate_db" {
  triggers = {
    db_endpoint = aws_db_instance.main.endpoint
  }

  provisioner "local-exec" {
    command = "./scripts/migrate.sh ${aws_db_instance.main.endpoint}"
  }
}
```

Quando `db_endpoint` muda, o `null_resource` é recriado, o provisioner roda de novo. É uma "fake dependency" com script atrelado.

## Boas práticas (se você for usar mesmo)

1. **Scripts externos** (`script = "..."`), não `inline`. Facilita teste e versionamento.
2. **Scripts idempotentes** — mesmo rodando duas vezes, resultado igual.
3. **Timeouts generosos** no `connection`.
4. **`on_failure = continue`** se você aceita falha (raro).
5. **Documente** por que você recorreu a provisioner.
6. **Plano pra migrar** para AMI/Ansible/cloud-init.

## Referências

- [Provisioners (last resort)](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax)
- [local-exec](https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec)
- [remote-exec](https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec)
- [file](https://developer.hashicorp.com/terraform/language/resources/provisioners/file)
- [cloud-init](https://cloud-init.io/)
