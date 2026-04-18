# Módulo 8 - Environments

Configurar dev, hml e prod com o mesmo código é um dos grandes valores do Terraform — e também uma das áreas de mais armadilhas. Este módulo cobre os mecanismos (variáveis, locals, outputs, workspaces, `.tfvars`) e as estratégias reais de mercado.

## Objetivos de aprendizagem

- Declarar e consumir **input variables** com tipos, defaults e validações.
- Usar **`locals`** para calcular valores internos de forma clara.
- Expor informações via **`outputs`**, com cuidados de sensibilidade.
- Entender **workspaces** e quando (não) usá-los.
- Dominar a precedência de fontes de valores (`.tfvars`, env, CLI, defaults).
- Comparar estratégias **multi-environment** (workspaces, diretórios, repositórios).

## Tópicos

1. [Input Variables](08_01-input-variables.md)
2. [Locals](08_02-locals.md)
3. [Outputs](08_03-outputs.md)
4. [Workspaces](08_04-workspaces.md)
5. [Arquivos `.tfvars` e precedência](08_05-tfvars-e-precedencia.md)
6. [Estratégias multi-environment](08_06-estrategias-multi-environment.md)
7. [Exercícios](08_07-exercicios/)

## Pré-requisitos

- Módulos 1 a 7 concluídos.
- Backend remoto configurado (opcional, mas recomendado para workspaces).

## Próximo passo

No Módulo 9 exploramos **HCL avançado**: `count`, `for_each`, expressões `for`, splat, `dynamic`, `lifecycle`, templates e funções built-in.
