# Exercício 04 - `.tfvars` por ambiente (diretórios)

## Objetivo

Usar **arquivos `.tfvars` separados** por ambiente e preparar o terreno para a estratégia híbrida de multi-environment.

## Estrutura sugerida

```
projeto/
├── main.tf
├── variables.tf
├── outputs.tf
├── envs/
│   ├── dev.tfvars
│   ├── hml.tfvars
│   └── prod.tfvars
```

## Tarefas

1. `variables.tf`:

   ```hcl
   variable "ambiente" {
     type = string
     validation {
       condition     = contains(["dev", "hml", "prod"], var.ambiente)
       error_message = "Use dev, hml ou prod."
     }
   }

   variable "instance_type" {
     type = string
   }

   variable "tags" {
     type = map(string)
     default = {}
   }
   ```

2. `envs/dev.tfvars`:

   ```hcl
   ambiente      = "dev"
   instance_type = "t3.micro"
   tags = {
     Owner      = "plataforma"
     CostCenter = "engineering"
   }
   ```

3. `envs/hml.tfvars`:

   ```hcl
   ambiente      = "hml"
   instance_type = "t3.small"
   tags = {
     Owner      = "plataforma"
     CostCenter = "engineering"
   }
   ```

4. `envs/prod.tfvars`:

   ```hcl
   ambiente      = "prod"
   instance_type = "t3.large"
   tags = {
     Owner      = "plataforma"
     CostCenter = "business"
   }
   ```

5. `main.tf` com uma EC2 que usa `var.instance_type`:

   ```hcl
   resource "aws_instance" "web" {
     ami           = data.aws_ami.ubuntu.id
     instance_type = var.instance_type

     tags = merge(
       {
         Name     = "web-${var.ambiente}"
         Ambiente = var.ambiente
       },
       var.tags,
     )
   }
   ```

6. Rode por ambiente:

   ```bash
   terraform plan  -var-file=envs/dev.tfvars
   terraform apply -var-file=envs/dev.tfvars

   # E depois:
   terraform plan  -var-file=envs/prod.tfvars
   ```

7. Teste override pontual:

   ```bash
   terraform plan -var-file=envs/prod.tfvars -var="instance_type=t3.xlarge"
   ```

## Pergunta chave

Qual a diferença **em termos de state** desse exercício para o anterior (workspaces)?

**Dica**: neste exercício, **cada `apply` sobrescreve** o mesmo state (uma única chave no backend). Em produção você combinaria isso com:

- Backends distintos (um por ambiente).
- Diretórios separados (`envs/dev/main.tf`, `envs/prod/main.tf`).

## Desafio extra

Transforme a estrutura para **diretórios**:

```
projeto/
├── modules/web/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── envs/
    ├── dev/
    │   ├── backend.tf
    │   ├── main.tf
    │   └── terraform.tfvars
    ├── hml/
    └── prod/
```

Onde `envs/dev/main.tf` é apenas:

```hcl
module "web" {
  source        = "../../modules/web"
  ambiente      = "dev"
  instance_type = var.instance_type
  tags          = var.tags
}
```

E cada `backend.tf` aponta para key diferente no S3.

Aplique em `envs/dev`, depois em `envs/prod`, e confirme que há dois states independentes.

## Perguntas

1. Por que backend.tf não pode usar variáveis?
2. Como o CI pipeline deve selecionar qual ambiente aplicar?
3. Se um colega roda `apply` em `prod`, há alguma forma técnica de impedir?
