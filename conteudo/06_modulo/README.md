# Módulo 6 - Providers

Providers são os **plugins** que conectam o Terraform Core às APIs dos serviços (AWS, GCP, Azure, Kubernetes, etc.). Este módulo detalha tudo que você precisa para declarar, configurar, autenticar, versionar e usar providers como um profissional.

## Objetivos de aprendizagem

- Entender o papel dos providers na arquitetura do Terraform.
- Declarar `required_providers` com versões corretas.
- Configurar o bloco `provider` de forma segura.
- Usar aliases para múltiplas instâncias (multi-região, multi-conta).
- Autenticar providers sem hardcodear credenciais.
- Navegar o Terraform Registry com discernimento.
- Consumir dados do ambiente via data sources.

## Tópicos

1. [O que são Providers](06_01-o-que-sao-providers.md)
2. [`required_providers`](06_02-required-providers.md)
3. [Configurando o bloco `provider`](06_03-configurando-provider.md)
4. [Aliases e múltiplas instâncias](06_04-aliases-multiplas-instancias.md)
5. [Autenticação e credenciais](06_05-autenticacao.md)
6. [Terraform Registry](06_06-registry.md)
7. [Data Sources](06_07-data-sources.md)
8. [Exercícios](06_08-exercicios/)

## Pré-requisitos

- Módulos 1 a 5 concluídos.
- Conta AWS (ou GCP/Azure) com credenciais configuradas.
- CLI Terraform ≥ 1.5 instalada.

## Próximo passo

No Módulo 7 aprofundamos **State** e backends (local, S3+DynamoDB, GCS, HTTP).
