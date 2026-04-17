# 02_04 - Multi-Cloud, Cloud Agnostic e Provider Agnostic

## Três conceitos parecidos — e bem diferentes

Esses três termos aparecem com frequência em pitches de Terraform, mas significam coisas distintas. Entender a diferença evita promessas exageradas e decisões ruins de arquitetura.

## 1. Multi-cloud

**Definição**: seu sistema **usa mais de um provedor de nuvem ao mesmo tempo**, cada um fazendo o que faz de melhor, sem pretensão de portabilidade.

Exemplo realista:
- **AWS** para backend de aplicação (EKS, RDS, S3).
- **GCP** para pipeline de dados (BigQuery, Dataflow).
- **Cloudflare** para DNS e WAF.
- **GitHub** para código e CI.
- **Datadog** para observabilidade.

Terraform é **ótimo** em multi-cloud: você declara providers de todas as plataformas no mesmo `terraform apply` e orquestra dependências entre eles.

```hcl
terraform {
  required_providers {
    aws        = { source = "hashicorp/aws" }
    cloudflare = { source = "cloudflare/cloudflare" }
  }
}

resource "aws_lb" "app" {
  # ...
}

resource "cloudflare_record" "app" {
  zone_id = var.cloudflare_zone_id
  name    = "app"
  content = aws_lb.app.dns_name
  type    = "CNAME"
}
```

O recurso Cloudflare depende do atributo da AWS. Terraform resolve naturalmente.

## 2. Cloud Agnostic

**Definição**: seu código **poderia rodar em qualquer nuvem sem mudança significativa**. Quase sempre é uma promessa furada.

A realidade é que **serviços "equivalentes" entre nuvens têm semânticas diferentes**:

- `aws_s3_bucket` ≠ `google_storage_bucket` ≠ `azurerm_storage_account`. Nomeação, lifecycle, permissões, replication, versionamento — tudo difere.
- IAM da AWS é um modelo; Cloud IAM da GCP é outro; RBAC do Azure é outro.
- Rede (VPC, subnets, route tables) tem abstrações parecidas mas com catch-22 em cada cloud.

Então, na prática:

- **Verdadeiramente cloud agnostic é raro** — geralmente só para coisas comoditizadas (VM básica, storage genérico, DNS).
- **Tentar forçar** é criar uma camada de abstração caseira cara e com bugs.
- **Kubernetes** é o único ambiente que chega perto de ser cloud agnostic em larga escala, porque expõe APIs uniformes.

Terraform **não garante** cloud agnostic. Ele só te permite **declarar recursos de várias nuvens com a mesma ferramenta**.

## 3. Provider Agnostic

**Definição**: o **core do Terraform** não conhece nenhuma nuvem específica. Toda integração com plataforma acontece via **providers**, que são plugins.

Isso significa:

- Amanhã alguém pode escrever um provider para uma nuvem nova (OCI, Digital Ocean, Tencent, Huawei, um SaaS qualquer) **sem mexer no core**.
- Você pode **escrever seu próprio provider** para sistemas internos da sua empresa.
- Core e providers evoluem em cadência independente.

Provider agnostic é uma **propriedade arquitetural** do Terraform, não uma promessa de portabilidade.

## Como Terraform *não* te vende ilusão

Um erro comum é achar que "vou usar Terraform pra ser cloud agnostic e trocar de AWS pra GCP amanhã se precisar". Na prática:

- **Cada provider tem seus recursos próprios** — `aws_instance` não existe no provider GCP.
- **Mudar de nuvem = reescrever o código Terraform**, módulo por módulo.
- O que o Terraform te dá é a **consistência do workflow** (init/plan/apply), não a portabilidade automática do código.

## Quando multi-cloud faz sentido

**Faz sentido:**
- Diversificar risco regulatório/geopolítico.
- Usar um serviço único que só existe em uma nuvem (ex.: BigQuery).
- Contratos legados em clouds diferentes.
- Disaster recovery entre regiões e clouds.

**Não faz sentido:**
- Só porque "é bonito no PowerPoint".
- Se o time não tem expertise em todas as clouds envolvidas.
- Se nenhum requisito real justifica a complexidade extra.

## Exemplos concretos

### Exemplo A: aplicação single-cloud com várias integrações (multi-cloud na prática)

```hcl
provider "aws" { region = "us-east-1" }
provider "cloudflare" {}
provider "datadog" {}
provider "github" {}

# infra AWS, DNS Cloudflare, monitores Datadog, repos GitHub
```

### Exemplo B: mesmo workload em duas clouds (arquitetura multi-cloud)

Um ambiente em AWS e outro em GCP, com código Terraform **separado** para cada, e uma camada de rede (Transit VPN, Interconnect) conectando.

### Exemplo C: tentativa frustrada de cloud agnostic

Alguém cria um módulo `modulo-object-storage` que aceita `var.cloud` e com `count`/`for_each` cria `aws_s3_bucket` ou `google_storage_bucket` dependendo do valor. Funciona em teoria; na prática vira um monstro conforme as features específicas de cada cloud começam a demandar atenção. Melhor ter dois módulos separados (`storage-aws`, `storage-gcp`) ou dois provedores em pilhas separadas.

## Resumo

| Conceito | Onde mora | Terraform entrega? |
|----------|-----------|-------------------|
| **Multi-cloud** | Arquitetura do seu sistema | Sim, excelente |
| **Cloud agnostic** | Portabilidade do seu código | Não automaticamente |
| **Provider agnostic** | Arquitetura do Terraform | Sim (é design) |

## Referências

- [HashiCorp — What is Multi-Cloud?](https://www.hashicorp.com/resources/what-is-multi-cloud)
- Charity Majors — posts sobre falácia do cloud agnostic
- [Terraform Registry](https://registry.terraform.io/) — prova viva do provider agnostic
