# 02_02 - Por que usar o Terraform

## Resumo

Se você leu o Módulo 1, já conhece os argumentos **a favor de IaC em geral**. Este tópico se concentra em **por que escolher Terraform especificamente**, comparado com alternativas nativas (CloudFormation, ARM) ou outras IaC (Pulumi, Ansible).

## Principais benefícios

### 1. Multi-cloud e independência de vendor

Com Terraform, o mesmo **workflow** (init, plan, apply) serve para AWS, GCP, Azure, Kubernetes, GitHub, Cloudflare, Datadog, PagerDuty e ~3000 outros providers. Você aprende **uma ferramenta** e aplica em toda a sua stack.

CloudFormation só serve pra AWS. ARM só pra Azure. Se sua empresa tem workload em mais de uma nuvem (ou planeja ter), Terraform elimina a necessidade de manter dois ou três DSLs diferentes.

### 2. Declarativo + plan antes de apply

A combinação **declarativo + `terraform plan`** é o "killer feature" do Terraform:

- Você descreve o estado desejado.
- `plan` mostra **exatamente** o que vai acontecer: cria, destrói, modifica, substitui.
- Só então `apply`.

Isso transforma "mexer em produção" de um ato de fé em um ato auditado.

### 3. Ecossistema e comunidade

- **Terraform Registry** com milhares de providers oficiais e de terceiros.
- **Módulos públicos** para cenários comuns (VPC, EKS, RDS, Kubernetes) — reuso de infra com versionamento.
- **Documentação extensa** e comunidade ativa em fóruns, Discord, Slack, Stack Overflow.
- **Integração** com todas as principais ferramentas de CI/CD (GitHub Actions, GitLab CI, Jenkins, Azure DevOps).

### 4. State como "fonte da verdade"

O Terraform mantém um **arquivo de state** que representa "o que foi provisionado por esse código". Isso permite:

- **Diff determinístico** entre desejado e real.
- **Detecção de drift** (alguém mudou manualmente na nuvem).
- **Refatoração segura** (`terraform state mv` para renomear recursos sem recriar).
- **Inspeção** (`terraform show`, `terraform output`).

O Módulo 7 é inteiro sobre state.

### 5. Imutabilidade natural

Terraform trata recursos como **unidades substituíveis**. Se um atributo não-mutável muda (ex.: nome de um bucket), o Terraform destrói e recria. Essa semântica casa bem com arquiteturas imutáveis (ver [01_03](../01_modulo/01_03-infraestrutura-imutavel.md)).

### 6. Reutilização via módulos

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "minha-vpc"
  cidr = "10.0.0.0/16"
  # ...
}
```

Três linhas = VPC com 4 subnets (2 públicas, 2 privadas), NAT gateway, route tables, flow logs. Você não reinventa a roda.

### 7. Aprovado em produção em escala

Netflix, Uber, Airbnb, Shopify, Stripe, GitHub, Cloudflare — praticamente qualquer empresa de tecnologia grande usa Terraform em algum nível. Não é risco adotar.

## Quando Terraform **não** é a melhor escolha

Sempre há contexto em que a ferramenta "certa" é outra:

- **Só AWS, sem intenção de mudar e time já domina**: CloudFormation/CDK pode ter integração mais profunda com serviços AWS recém-lançados.
- **Configuração de SO dentro de VMs**: Ansible/Puppet fazem isso melhor (Terraform não é feito pra "instalar pacote X e configurar arquivo Y").
- **Time resistente a DSL**: Pulumi pode ser mais aceito porque usa Python/TypeScript/Go direto.
- **Recursos dinâmicos calculados em runtime com lógica complexa**: Pulumi ou CDK (CloudFormation) pode ser mais expressivo.
- **Kubernetes-nativo puro**: Helm, Kustomize ou operators podem ser mais idiomáticos dentro do cluster.

Mesmo assim, é comum combinar: **Terraform pra infra de nuvem, outra ferramenta para um nicho específico**.

## Limitações conhecidas

- **State precisa ser gerenciado** com cuidado (lock, backup, segredos).
- **Refatoração pode ser dolorosa** se não for planejada (mover recursos entre módulos exige `state mv`).
- **Erros de provider** acontecem — às vezes você pisa num bug da integração com a API da nuvem.
- **Drift** é real: pessoas ainda mexem no console e a vida acontece.
- **Provisioners** são um último recurso e rodam com garantias fracas.
- **Plan nem sempre prevê 100%**: algumas mudanças só aparecem no apply.

Nada disso invalida a escolha do Terraform, mas são realidades operacionais que o curso vai te preparar a lidar.

## Em uma linha

Terraform é a ferramenta mais **portável**, **comunitária**, **confiável** e **padronizada** de IaC disponível hoje para quem precisa gerenciar infraestrutura heterogênea com segurança e velocidade.

## Referências

- [Terraform Case Studies](https://www.hashicorp.com/case-studies)
- [Pulumi vs Terraform](https://www.pulumi.com/docs/concepts/vs/terraform/) — ótima leitura "o lado de lá"
- *Terraform Up & Running* — Yevgeniy Brikman (livro referência)
