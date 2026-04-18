# Exercício 14 - Provisioners (com cautela)

## Contexto

Você quer subir uma EC2 com Nginx instalado. Este exercício demonstra **como usar provisioners** — e ao final, apresenta a alternativa preferida (cloud-init).

## Objetivo

Experimentar `remote-exec` e, em seguida, reescrever com `user_data` para comparar.

## Pré-requisitos

- Credenciais AWS.
- Par de chaves SSH: gere com `ssh-keygen -t rsa -f ~/.ssh/terraform_lab -N ""` se não tem.
- Importe a chave pública para AWS (console → EC2 → Key Pairs) ou use o recurso Terraform.

## Parte 1 - Usando `remote-exec` (não recomendado em produção)

Crie `main.tf`:

```hcl
resource "aws_key_pair" "lab" {
  key_name   = "terraform-lab"
  public_key = file("~/.ssh/terraform_lab.pub")
}

resource "aws_security_group" "web" {
  name        = "lab-web"
  description = "Permite SSH e HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # laboratório apenas
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"  # Ubuntu 22.04 us-east-1
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable --now nginx",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/terraform_lab")
      host        = self.public_ip
      timeout     = "5m"
    }
  }

  tags = {
    Name = "lab-provisioner"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
```

Aplique:

```bash
terraform init
terraform apply
```

Após o apply, acesse `http://<public_ip>` e veja a página padrão do Nginx.

### Perguntas

- O provisioner apareceu **no plan**? Ou só no apply?
- Se você **alterar** o `inline` de pacotes, o Terraform vai re-rodar o provisioner? (Tente: adicione `curl` na lista e apply.)
- O que acontece se o SSH falhar? A EC2 fica em que estado?

## Parte 2 - Reescrevendo com `user_data` (preferido)

Substitua o `provisioner "remote-exec"` por `user_data`:

```hcl
resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable --now nginx
  EOF

  tags = {
    Name = "lab-userdata"
  }
}
```

Destrua e recrie:

```bash
terraform destroy
terraform apply
```

Aguarde ~1 min. Acesse o IP — Nginx deve estar servindo.

### Comparação

| Aspecto | `remote-exec` | `user_data` |
|---------|:-------------:|:-----------:|
| Aparece no plan? | Não | Sim |
| Precisa SSH aberto? | Sim | Não |
| Muda o script → recria? | Não | Sim (in-place ou replace) |
| Idiomático? | Legacy | Recomendado |
| Logs | No terminal do apply | `/var/log/cloud-init-output.log` na VM |

## Limpeza

```bash
terraform destroy
```

## Reflexão

- Em que cenário `remote-exec` **seria** a única opção?
- E se você precisasse instalar pacotes que exigem múltiplos reboots? (dica: Packer.)

## Critério de conclusão

- Você conseguiu rodar ambos os fluxos.
- Entendeu a diferença prática entre `provisioner` e `user_data`.
- Consegue argumentar por que `user_data` (ou AMI pré-buildada) é superior.

## Referências

- [Tópico 04_09 - Provisioners](../04_09-provisioners.md)
- [cloud-init](https://cloudinit.readthedocs.io/)
- [Packer](https://developer.hashicorp.com/packer)
