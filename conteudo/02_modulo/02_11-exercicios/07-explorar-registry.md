# Exercício 07 - Explorar o Terraform Registry

## Objetivo

Familiarizar-se com o [Terraform Registry](https://registry.terraform.io/) — fonte primária para consultar providers e descobrir módulos reutilizáveis.

## Tarefas

### 1. Providers

Acesse [registry.terraform.io/browse/providers](https://registry.terraform.io/browse/providers) e responda:

1. Qual o selo (**Official**, **Partner** ou **Community**) dos providers `hashicorp/aws`, `cloudflare/cloudflare`, `datadog/datadog`, `PagerDuty/pagerduty`?
2. Encontre o provider da **AWS**. Qual é a **versão mais recente**? Qual o número de **downloads**? Qual é a **linguagem** (só pra curiosidade)?
3. Dentro da doc do provider AWS, abra a página do recurso `aws_s3_bucket`. Liste **cinco** atributos aceitos e o que cada um significa.

### 2. Módulos

Acesse [registry.terraform.io/browse/modules](https://registry.terraform.io/browse/modules) e explore:

1. Procure por `vpc` no provider AWS. Qual módulo aparece em primeiro (o "oficial" da comunidade)?
2. Abra a página desse módulo. Quais são as suas **principais variáveis de entrada** (inputs)?
3. Qual o comando HCL exato para importar esse módulo na versão mais recente?

### 3. Pratique

Escreva um arquivo `main.tf` que use o módulo comunitário de VPC:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "exploracao-registry"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = false

  tags = {
    Projeto = "aprendizado"
  }
}
```

Rode:

```bash
terraform init
terraform plan
```

**Não aplique** (uma VPC tem muitos recursos). Apenas observe:

- Quantos recursos serão criados?
- Que tipo de recursos aparecem?

### 4. Conclusões

1. Qual a diferença prática entre escrever manualmente `aws_vpc + aws_subnet + aws_route_table + ...` vs. usar o módulo público?
2. Quais são os **riscos** de usar um módulo da comunidade em produção?
3. O que você checaria em um módulo antes de confiar nele em produção?

## Critério de conclusão

- Entendimento claro das diferenças entre providers Official/Partner/Community.
- Capacidade de consultar docs de providers sem precisar de blog.
- Um plan rodado com sucesso usando módulo do Registry.

## Referências

- [Terraform Registry](https://registry.terraform.io/)
- [Tópico 02_07 - Comunidade e documentação](../02_07-suporte-documentacao-comunidade.md)
