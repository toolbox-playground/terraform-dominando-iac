# Módulo 7 - State

State é o coração operacional do Terraform. Sem ele, não há `plan`, não há drift detection, não há colaboração. Este módulo ensina a operar o state com segurança.

## Objetivos de aprendizagem

- Entender o que é o state e por que ele existe.
- Trabalhar com state local e saber quando promover.
- Configurar backends remotos (S3, GCS, Azure, HTTP, Terraform Cloud).
- Garantir locking para evitar corrupção.
- Proteger dados sensíveis no state.
- Operar state via CLI com segurança (`list`, `show`, `mv`, `rm`, `pull`, `push`).
- Migrar entre backends e compor states com `terraform_remote_state`.

## Tópicos

1. [O que é o State](07_01-o-que-e-state.md)
2. [State Local](07_02-state-local.md)
3. [Backends Remotos](07_03-backends.md)
4. [State Locking](07_04-state-locking.md)
5. [Dados Sensíveis no State](07_05-dados-sensiveis.md)
6. [Operações de State CLI (revisão prática)](07_06-state-operations.md)
7. [Migração de Backends](07_07-migracao-backends.md)
8. [Exercícios](07_08-exercicios/)

## Pré-requisitos

- Módulos 1 a 6 concluídos.
- Conta AWS com permissão para criar bucket S3 e DynamoDB.

## Próximo passo

No Módulo 8 tratamos **environments**: variáveis, `locals`, `outputs`, workspaces e estratégias para dev/hml/prod.
