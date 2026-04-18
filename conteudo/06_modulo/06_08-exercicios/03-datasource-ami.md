# Exercício 03 - Data source: buscar AMI Ubuntu mais recente

*(Integra o exercício original `exercicios/2_intermediarios/17.md` - Datasources e Local Values.)*

## Objetivo

- Usar `data "aws_ami"` para obter a AMI Ubuntu mais recente.
- Organizar a saída em `locals`.
- Expor via `output`.

## Tarefas

1. Crie `data "aws_ami" "ubuntu"` filtrando por:
   - `owners = ["099720109477"]` (Canonical).
   - `name` começando com `ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*`.
   - `most_recent = true`.
2. Em `locals`, defina:
   ```hcl
   locals {
     instancia = {
       ami           = data.aws_ami.ubuntu.id
       instance_type = "t3.micro"
       arch          = data.aws_ami.ubuntu.architecture
     }
   }
   ```
3. Crie um `aws_instance` usando `local.instancia.ami` e `local.instancia.instance_type`.
4. Exponha um `output` mostrando `local.instancia`.
5. Rode `terraform plan` e depois `terraform console`. No console, teste:
   ```
   > data.aws_ami.ubuntu.id
   > data.aws_ami.ubuntu.creation_date
   > local.instancia
   ```

## Perguntas

1. Se a AMI mais recente mudar entre um `plan` e outro, o que acontece com `aws_instance`?
2. Como travar a AMI em uma específica (sem alterar entre runs)?
3. Por que data source roda no refresh mesmo sem mudanças no código?
