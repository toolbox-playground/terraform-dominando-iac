# 02_07 - Suporte, Documentação e Comunidade

## Filosofia

O Terraform tem um dos ecossistemas de IaC mais **maduros e ativos** do mercado. Saber **onde procurar ajuda** é quase tão importante quanto saber a sintaxe. Este tópico é o seu mapa.

## Documentação oficial

### developer.hashicorp.com/terraform

[developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform) é a **referência primária**. Estrutura:

- **Intro** — conceitos introdutórios, comparações com outras ferramentas.
- **Install** — instalação em todos os SOs.
- **Tutorials** — *tutoriais guiados* por cenário (AWS, GCP, Azure, Kubernetes, CI/CD).
- **Docs / Language** — **a bíblia do HCL**: blocos, expressões, funções, meta-arguments.
- **Docs / CLI** — referência de todos os comandos.
- **Docs / Internals** — arquitetura, grafo, plugin protocol.
- **Registry** — catálogo de providers e módulos.

Dica: **sempre prefira a doc oficial antes de blogs e Stack Overflow**. Blog post de 2018 pode estar descrevendo sintaxe depreciada (`aws_s3_bucket_acl` em vez de `aws_s3_bucket` + argumento `acl`, por exemplo).

### Terraform Registry — [registry.terraform.io](https://registry.terraform.io/)

- **Providers oficiais** (AWS, GCP, Azure, etc.) com documentação de **cada resource e data source**.
- **Módulos públicos** — reuso pronto para cenários comuns (VPC AWS, EKS, RDS, etc.).
- Filtros: **Official** (HashiCorp), **Partner** (empresas verificadas), **Community** (qualquer um).

Exemplo: [registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) mostra **todos os atributos** aceitos pelo recurso `aws_s3_bucket`, com exemplos.

**Não tente adivinhar atributos. Abra o Registry.**

## HashiCorp Learn

Em [developer.hashicorp.com/tutorials](https://developer.hashicorp.com/tutorials), há trilhas guiadas gratuitas:

- **Get Started** em várias clouds.
- **Associate Certification** — preparação para a prova HashiCorp Certified: Terraform Associate.
- **Advanced** — módulos, policies, testes, CI/CD.

São passo a passo muito bons, com repositórios de exemplo no GitHub.

## GitHub e issue trackers

Cada provider tem seu próprio repositório. Alguns importantes:

- [github.com/hashicorp/terraform](https://github.com/hashicorp/terraform) — o core
- [github.com/hashicorp/terraform-provider-aws](https://github.com/hashicorp/terraform-provider-aws)
- [github.com/hashicorp/terraform-provider-google](https://github.com/hashicorp/terraform-provider-google)
- [github.com/hashicorp/terraform-provider-azurerm](https://github.com/hashicorp/terraform-provider-azurerm)

Ao ficar travado num comportamento estranho, **pesquise o erro exato no issue tracker**. Muito provavelmente já foi reportado.

## Fóruns e chat

- **[discuss.hashicorp.com](https://discuss.hashicorp.com/)** — fórum oficial com categoria Terraform ativa.
- **Community Slack da HashiCorp** — canais por provider, por tópico.
- **Reddit** — [r/Terraform](https://www.reddit.com/r/Terraform/).
- **Stack Overflow** — tag `terraform`.

## Comunidade em português

- **Discord Toolbox Playground** — [link](https://discord.gg/XP8kQvpW) (comunidade deste curso).
- **LinkedIn** — muitos profissionais brasileiros postam sobre Terraform.
- **YouTube** em PT-BR — canais de DevOps com trilhas completas.
- **Meetups locais** — procure em São Paulo, Curitiba, BH, Recife, Porto Alegre.

## Livros recomendados

- *Terraform: Up & Running* — **Yevgeniy Brikman** (O'Reilly). Leitura obrigatória para quem quer dominar.
- *Infrastructure as Code* — **Kief Morris** (O'Reilly). Conceitos mais amplos de IaC.
- *The Terraform Book* — James Turnbull. Mais prático e direto.

## Certificação

A HashiCorp oferece a **HashiCorp Certified: Terraform Associate**:

- Prova online, ~60 questões, 1h.
- Valida conhecimento em HCL, workflow, state, providers, módulos.
- **Boa métrica** de que você está no caminho certo, mas não substitui experiência real.
- Este curso te dá a base mais que suficiente para tirar a certificação.

Mais info: [developer.hashicorp.com/terraform/tutorials/certification-003](https://developer.hashicorp.com/terraform/tutorials/certification-003).

## OpenTofu — a alternativa comunitária

Desde 2023, o **OpenTofu** mantido pela Linux Foundation é uma alternativa open-source ao Terraform após a mudança de licença (BSL) da HashiCorp. O OpenTofu:

- É **fork do Terraform 1.5**.
- Tem sintaxe e workflow **idênticos** (os comandos são `tofu init`, `tofu plan`, etc., mas o HCL e providers são compatíveis).
- Governança independente.
- [opentofu.org](https://opentofu.org/).

Este curso usa Terraform, mas tudo que você aprender aqui se aplica diretamente ao OpenTofu.

## Como fazer uma pergunta decente ao pedir ajuda

Pra maximizar chance de resposta boa:

1. **Qual versão do Terraform e do provider** você está usando? (`terraform version`)
2. **Código mínimo reproduzível** (não cole 500 linhas).
3. **Saída exata do erro** (não parafraseie).
4. **O que você já tentou** e o resultado.
5. **O que espera acontecer** vs. o que está acontecendo.

Isso vale pra Stack Overflow, GitHub issue, Discord, Slack — qualquer canal.

## Resumo

- **Dúvida de sintaxe de recurso** → Registry do provider.
- **Dúvida conceitual** → docs oficiais `/language/`.
- **Erro estranho** → GitHub issues do provider.
- **Dúvida de workflow/CI** → Learn tutorials.
- **Papo, dicas, networking** → Discord Toolbox Playground e fóruns.

## Referências

- [Terraform Docs](https://developer.hashicorp.com/terraform)
- [Terraform Registry](https://registry.terraform.io/)
- [HashiCorp Discuss](https://discuss.hashicorp.com/)
- [OpenTofu](https://opentofu.org/)
