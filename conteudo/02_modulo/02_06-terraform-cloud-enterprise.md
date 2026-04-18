# 02_06 - Terraform Cloud e Enterprise

## Três versões do Terraform

A HashiCorp oferece o Terraform em três sabores:

| Versão | Como consumir | Público | Custo |
|--------|--------------|--------|-------|
| **Terraform OSS (CLI)** | Binário `terraform` rodando local ou em CI | Todo mundo | Grátis (com licença BSL desde 2023) |
| **HCP Terraform** (antigo Terraform Cloud) | SaaS hospedado pela HashiCorp | Times e empresas | Free tier + planos pagos |
| **Terraform Enterprise** | Self-hosted na sua infraestrutura | Grandes empresas, governo | Licenciamento anual |

Este curso cobre tudo com base no OSS — tudo que você aprende funciona em qualquer uma das três.

## O que o HCP Terraform / Enterprise adicionam ao OSS

O OSS te dá **a ferramenta**. Cloud e Enterprise adicionam **uma plataforma completa** em cima:

### 1. Remote State gerenciado

- State armazenado na HashiCorp (Cloud) ou no seu datacenter (Enterprise).
- Lock automático.
- Versionamento e histórico.
- Encryption at rest.
- Sem precisar configurar S3 + DynamoDB manualmente.

### 2. Remote Runs

O `plan` e `apply` rodam **na infraestrutura da plataforma**, não na sua máquina. Benefícios:

- Pipelines padronizados.
- Credenciais de nuvem ficam no ambiente do Cloud (não na máquina do dev).
- Logs centralizados.
- Concurrency controlada (runs enfileirados por workspace).

### 3. Workspaces como primeira classe

No OSS, workspace é só um namespace dentro de um state. No HCP, **workspace é a unidade de organização**: tem variáveis, runs, policies, histórico, permissões próprias.

### 4. VCS Integration

- Conecta GitHub, GitLab, Bitbucket, Azure DevOps.
- Plan automático em PR.
- Apply automático (ou com aprovação) ao merge.
- Sem precisar montar CI/CD do zero.

### 5. Políticas (Sentinel / OPA)

- Define políticas como código: "não pode criar EC2 gigante", "buckets precisam ter encryption", "tags obrigatórias".
- Rodam **antes do apply**, bloqueando violações.
- Sentinel é proprietário HashiCorp; OPA é open-source (ambos suportados).

### 6. RBAC e SSO

- Usuários, times, permissões granulares.
- SSO via SAML/OIDC.
- Auditoria de quem fez o quê.

### 7. Private Module Registry

- Publicar módulos internos da sua empresa com versionamento.
- Descoberta e documentação no portal.
- Sem precisar expor no GitHub público.

### 8. Cost Estimation

- Antes de apply, mostra impacto em custo mensal estimado (baseado em recursos que afetam billing).
- Útil em políticas de aprovação.

## Comparação rápida

| Feature | OSS | HCP Terraform | Enterprise |
|---------|:---:|:-------------:|:----------:|
| CLI `terraform` | Sim | Sim (usa o mesmo) | Sim |
| Remote state gerenciado | Não (você configura backend) | Sim | Sim |
| Remote runs | Não | Sim | Sim |
| VCS integration | Não | Sim | Sim |
| Sentinel policies | Não | Parcial/pago | Sim |
| OPA policies | Não | Sim | Sim |
| Private registry | Não (pode simular) | Sim | Sim |
| SSO/SAML | Não | Pago | Sim |
| Self-hosted | Não | Não | Sim |
| Air-gapped (sem internet) | Possível | Não | Sim |
| Free tier | Grátis completo | Sim (até N workspaces) | Não (licença) |

## Quando usar cada um

- **Só eu, projetos pequenos** → OSS + state local ou S3 básico.
- **Time pequeno, sem budget para plataforma** → OSS + backend remoto (S3+DynamoDB, GCS, Azure Blob, GitLab HTTP).
- **Time médio, quer padronização e colaboração** → HCP Terraform (free tier já resolve muito).
- **Empresa grande, compliance rígido, air-gap, 100+ workspaces** → Enterprise.

## O que o curso cobre

O curso foca no **OSS + backends remotos em clouds (S3, GCS, GitLab HTTP)**. Isso te prepara para **qualquer** dos três cenários:

- Se você for usar Cloud/Enterprise depois, a curva é curta — o HCL é o mesmo, o workflow é o mesmo, só muda o "onde o plan roda".
- Se sua empresa usa OSS + CI próprio, você já está pronto.

## Como experimentar o HCP Terraform gratuitamente

1. Crie conta em [app.terraform.io](https://app.terraform.io).
2. Crie uma organization.
3. Conecte com seu repositório GitHub/GitLab.
4. Crie um workspace apontando para uma pasta com `.tf`.
5. Configure variáveis (incluindo credenciais da nuvem).
6. Trigger um run pelo portal ou via push no repositório.

O free tier suporta equipes pequenas com workspaces limitados — suficiente pra aprender.

## Referências

- [HCP Terraform](https://developer.hashicorp.com/terraform/cloud-docs)
- [Terraform Enterprise](https://developer.hashicorp.com/terraform/enterprise)
- [Sentinel](https://www.hashicorp.com/sentinel)
- [OPA + Terraform](https://www.openpolicyagent.org/docs/latest/terraform/)
