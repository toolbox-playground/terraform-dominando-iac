# Módulo 4 - Terraform Core Workflow P2

Continuação do Módulo 3: operações de manutenção, investigação e recuperação.

## Objetivos de aprendizagem

- Destruir infraestrutura de forma controlada.
- Entender dependências implícitas vs. explícitas.
- Lidar com drift e sincronizar state com realidade.
- Importar recursos existentes para dentro do Terraform.
- Forçar recriação pontual com `-replace`.
- Depurar expressões com `terraform console`.
- Manipular state via `terraform state ...` com segurança.
- Reconhecer quando (não) usar provisioners.

## Tópicos

1. [Destroy](04_01-destroy.md)
2. [Dependências Implícitas](04_02-dependencias-implicitas.md)
3. [Dependências Explícitas](04_03-dependencias-explicitas.md)
4. [Refresh e Drift](04_04-refresh-e-drift.md)
5. [Import](04_05-import.md)
6. [Taint, Untaint, Replace](04_06-taint-replace.md)
7. [Console](04_07-console.md)
8. [Operações de State CLI](04_08-state-cli.md)
9. [Provisioners](04_09-provisioners.md)
10. [Exercícios](04_10-exercicios/)

## Próximo passo

Módulo 5 aprofunda **HCL**, a linguagem de configuração do Terraform.
