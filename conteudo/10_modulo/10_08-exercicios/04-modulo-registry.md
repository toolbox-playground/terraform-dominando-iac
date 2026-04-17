# Exercício 04 - Consumindo módulo da Terraform Registry

## Objetivo

Consumir um módulo bem conhecido da Terraform Registry pública para aprender a integrar módulos versionados no seu código.

## Tarefa

1. Usar o módulo `terraform-aws-modules/vpc/aws` para criar uma VPC com:
   - CIDR `10.0.0.0/16`
   - 2 subnets públicas e 2 privadas
   - NAT Gateway único
   - `enable_dns_hostnames = true`
2. Fixar versão com `~> 5.0`.
3. Criar um `aws_security_group` que receba o `vpc_id` via `module.vpc.vpc_id`.
4. Expor outputs que reempacotem os outputs do módulo.
5. Rodar `terraform init` e observar o download em `.terraform/modules/`.

## Dicas

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "exercicio-registry"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway  = true
  single_nat_gateway  = true
  enable_dns_hostnames = true

  tags = {
    ManagedBy = "terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
```

## Verificação

```bash
terraform init
# Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.x.y ...

terraform plan
# Deve criar VPC, 4 subnets, IGW, NAT, route tables...

ls .terraform/modules/
```

## Desafio extra

- Trocar `single_nat_gateway = true` para `false` e observar o custo adicional no plan (1 NAT por AZ).
- Consultar os Inputs/Outputs na [página do módulo](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest) e explorar features como peering, VPN, flow logs.
