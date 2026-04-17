# Módulo 10 - Módulos

Módulos são a unidade de **reuso e encapsulamento** em Terraform. Dominar módulos é o que separa scripts IaC "funcionais" de uma plataforma de infraestrutura bem desenhada.

## Objetivos de aprendizagem

- Entender o que é um módulo e quando criar um.
- Estruturar módulos com convenções do ecossistema (`main.tf`, `variables.tf`, `outputs.tf`, `examples/`).
- Projetar interfaces claras com inputs validados e outputs mínimos.
- Consumir módulos locais, Git, Registry pública e privada.
- Versionar com SemVer e pinning com tags.
- Compor módulos em stacks maiores.
- Publicar em registries privadas (preparação para Módulo 11).

## Tópicos

1. [O que são Módulos](10_01-o-que-sao-modulos.md)
2. [Criando seu primeiro módulo](10_02-criando-primeiro-modulo.md)
3. [Inputs e Outputs](10_03-inputs-e-outputs.md)
4. [Fontes e versionamento](10_04-fontes-e-versionamento.md)
5. [Layout e organização de código](10_05-layout-e-organizacao.md)
6. [Padrões avançados](10_06-padroes-avancados.md)
7. [Terraform Registry e publicação](10_07-registry-e-publicacao.md)
8. [Exercícios](10_08-exercicios/)

## Filosofia

> "Módulos são funções. Inputs são argumentos. Outputs são retorno. Trate-os como trataria qualquer API."

Crie módulos pequenos, com interface estável, bem documentados e versionados. A tentação de criar um "super módulo" que resolve tudo é real — resista.

## Próximo passo

O Módulo 11 mostra como **publicar e consumir** módulos via GitLab CI/CD, fechando o ciclo com pipelines versionados e estado remoto.
