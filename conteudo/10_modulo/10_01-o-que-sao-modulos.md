# 10_01 - O que são Módulos

## Definição

Um **módulo** Terraform é um **conjunto de arquivos `.tf` em um diretório**. É a unidade básica de **reuso e encapsulamento** em Terraform — o equivalente a uma função, biblioteca ou pacote em linguagens de programação.

Tudo que você escreveu até agora **já é um módulo**: o diretório raiz onde você roda `terraform apply` é chamado de **root module**.

## Nomenclatura

| Termo | Significado |
|-------|-------------|
| **Root module** | Diretório onde você roda `terraform init/apply`. |
| **Child module** | Módulo chamado por outro (via bloco `module`). |
| **Published module** | Módulo hospedado num registry (Terraform Registry, GitLab, S3). |
| **Local module** | Módulo em diretório local referenciado via `source = "./path"`. |

## Estrutura típica

```
modulo-vpc/
├── README.md         # documentação de uso
├── versions.tf       # terraform{} + required_providers
├── variables.tf      # inputs
├── main.tf           # recursos
├── outputs.tf        # exports
└── examples/         # exemplos de uso
    └── basico/
        └── main.tf
```

Nenhum arquivo é obrigatório com esses nomes — Terraform lê **todos** os `.tf` do diretório. Mas esta convenção ajuda a orientar quem consome.

## Por que modularizar

1. **Reutilização**: escreva uma VPC **uma vez** e use em 10 ambientes.
2. **Encapsulamento**: esconde detalhes de implementação; expõe apenas `variables` e `outputs`.
3. **Padronização**: todo time usa a mesma "receita" (tags, conventions, security defaults).
4. **Testabilidade**: módulos pequenos são testáveis isoladamente.
5. **Versionamento**: mudanças controladas via `version = "x.y.z"`.
6. **Colaboração**: times diferentes mantêm módulos diferentes (plataforma mantém rede, squads consomem).

## Anti-padrão: "megamódulo"

Não crie um módulo que provisiona tudo: VPC + RDS + EKS + Monitoramento + CI/CD.

- Mudanças num ponto afetam tudo.
- Blast radius enorme.
- Dificulta testes.
- Acopla componentes que deveriam evoluir separado.

**Prefira** múltiplos módulos pequenos e componíveis.

## Exemplo: chamada de módulo

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "minha-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  tags = local.tags
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id     = module.vpc.private_subnets[0]   # <-- output do módulo
}
```

O bloco `module "vpc" { }` é **uma chamada** ao módulo — como uma chamada de função.

## Fluxo de dados

```
┌─────────────────────────────┐
│  root module (caller)       │
│  ┌───────────────────────┐  │
│  │ inputs (variables)    │  │
│  └──────────┬────────────┘  │
│             ▼               │
│  ┌───────────────────────┐  │
│  │ child module          │  │
│  │  - recursos           │  │
│  │  - data sources       │  │
│  │  - locals             │  │
│  └──────────┬────────────┘  │
│             ▼               │
│  ┌───────────────────────┐  │
│  │ outputs               │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

- **Inputs** entram pelo bloco `module {}`.
- **Outputs** ficam disponíveis em `module.NOME.output_x`.

## Escopo isolado

Dentro de um módulo:

- `var.x` refere-se às variáveis **do próprio módulo** (não do pai).
- Para expor algo ao pai, você **precisa** declarar um `output`.
- Providers são herdados do pai (ou configurados via `configuration_aliases`).
- State do módulo é **parte do state do root**, mas com paths prefixados (`module.vpc.aws_vpc.main`).

## Quando criar um módulo

Crie um módulo quando:

- Você se pegar **copiando** o mesmo bloco de recursos para outro projeto.
- Você quer **esconder complexidade** (ex.: RDS com backup, encryption, parameter groups, todos os detalhes).
- Vários times precisam provisionar a mesma coisa com **variações pequenas**.
- Você quer **padronizar tags, naming, policies** em toda a empresa.

**Não crie** um módulo:

- Apenas para "envolver" 1 recurso sem adicionar valor.
- Quando o uso é único e provavelmente não se repetirá.
- Antes de ter pelo menos 2-3 consumidores claros em mente (evita over-engineering).

## Fontes de módulos

Um bloco `module` pode apontar para:

1. **Diretório local**: `source = "./modules/vpc"`
2. **Git**: `source = "git::https://github.com/org/modulo.git?ref=v1.2.0"`
3. **Registry oficial**: `source = "terraform-aws-modules/vpc/aws"`
4. **Registry privado**: `source = "app.terraform.io/minha-org/vpc/aws"`
5. **S3/GCS**: `source = "s3::https://s3-eu-west-1.amazonaws.com/bucket/modulo.zip"`
6. **HTTP**: URL com archive.
7. **GitLab**: Terraform Module Registry nativo do GitLab.

Detalhado no tópico `10_06-fontes-e-versionamento`.

## Resumo

- Módulo = diretório com arquivos `.tf`.
- Root module = onde você roda Terraform.
- Child module = chamado via `module { source = ... }`.
- Interface = `variables` (entrada) + `outputs` (saída).
- Motivação = reuso, padronização, encapsulamento.

Próximo tópico: **criando seu primeiro módulo**.
