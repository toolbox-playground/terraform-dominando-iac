# Exercício 01 - Seu primeiro módulo

*(Integra o exercício original 16)*

## Objetivo

Modularizar uma configuração simples: criar um módulo que recebe inputs e expõe outputs.

## Tarefa

1. Criar estrutura:
   ```
   projeto/
   ├── main.tf
   ├── versions.tf
   └── modules/
       └── ec2-basica/
           ├── main.tf
           ├── variables.tf
           └── outputs.tf
   ```
2. No módulo `ec2-basica`, receber inputs:
   - `nome` (string, obrigatório).
   - `instance_type` (string, default `"t3.micro"`).
   - `ami_id` (string, obrigatório).
   - `tags` (map(string), default `{}`).
3. Criar uma `aws_instance` com esses inputs.
4. Expor outputs:
   - `id` — ID da instância.
   - `public_ip` — IP público.
   - `arn`.
5. No `main.tf` raiz, consumir o módulo criando **duas** instâncias (`web-01` e `web-02`).
6. Rodar `init`, `plan`, `apply`, e validar via `terraform state list`.

## Dicas

```hcl
module "ec2_web_01" {
  source = "./modules/ec2-basica"

  nome          = "web-01"
  instance_type = "t3.micro"
  ami_id        = data.aws_ami.ubuntu.id

  tags = {
    Role = "web"
  }
}

output "web_01_ip" {
  value = module.ec2_web_01.public_ip
}
```

## Verificação

```bash
terraform init
terraform apply
terraform state list
# module.ec2_web_01.aws_instance.this
# module.ec2_web_02.aws_instance.this
```

## Desafio extra

- Adicionar `validation` em `nome` (tamanho entre 3 e 30).
- Adicionar `for_each` no bloco `module` pra criar N instâncias a partir de um map.
