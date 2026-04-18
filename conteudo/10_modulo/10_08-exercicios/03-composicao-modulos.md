# Exercício 03 - Composição de módulos (VPC + EC2 + SG)

## Objetivo

Compor múltiplos módulos locais criando uma stack completa: rede + security group + instância aplicacional.

## Tarefa

1. Criar 3 módulos em `modules/`:
   - `rede/` → cria `aws_vpc`, 1 `aws_subnet` pública, `aws_internet_gateway`, `aws_route_table` + associação. Exporta `vpc_id`, `subnet_id`.
   - `sg/` → recebe `vpc_id`, cria `aws_security_group` com regras de ingress configuráveis. Exporta `sg_id`.
   - `ec2/` → recebe `subnet_id`, `sg_ids`, `ami_id`. Cria `aws_instance`. Exporta `id`, `public_ip`.
2. No root, encadear os módulos:
   ```hcl
   module "rede" { source = "./modules/rede" ... }
   module "sg"   { source = "./modules/sg"
     vpc_id = module.rede.vpc_id
     ...
   }
   module "web"  { source = "./modules/ec2"
     subnet_id = module.rede.subnet_id
     sg_ids    = [module.sg.sg_id]
     ...
   }
   ```
3. Apply e validar que o recurso é alcançável.
4. Destruir toda a stack com `terraform destroy`.

## Dicas

- Use `data "aws_ami" "ubuntu"` no root e passe o ID para o módulo `ec2`.
- O módulo `sg` deve aceitar uma lista de regras de ingress (veja Módulo 9, dynamic blocks).
- Cuide para que o SG permita saída total (egress).

## Verificação

```bash
terraform state list
# module.rede.aws_vpc.this
# module.rede.aws_subnet.public
# ...
# module.sg.aws_security_group.this
# module.web.aws_instance.this

terraform output
# Deve conter o IP público da instância.
```

## Desafio extra

- Trocar a subnet única por **duas** subnets em AZs diferentes usando `for_each` no módulo `rede`.
- Distribuir instâncias entre as subnets.
- Adicionar um `aws_lb` na frente.
