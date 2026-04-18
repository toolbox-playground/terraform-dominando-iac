# Módulo 3 - Terraform Core Workflow

Este módulo detalha **cada etapa** do ciclo Write → Plan → Create (WPC) — o coração do uso diário do Terraform.

## Objetivos de aprendizagem

Ao final deste módulo, você será capaz de:

- Entender cada etapa do ciclo WPC e quando usá-la.
- Escrever HCL limpo e versionado.
- Usar `fmt` e `validate` como parte do ciclo de desenvolvimento.
- Rodar `init` entendendo providers e lock file.
- Ler a saída do `plan` e interpretar símbolos.
- Aplicar mudanças com segurança, usando planos salvos.

## Tópicos

1. [Flow WPC](03_01-flow-wpc.md)
2. [Write](03_02-write.md)
3. [Validate](03_03-validate.md)
4. [FMT](03_04-fmt.md)
5. [Init](03_05-init.md)
6. [Plan](03_06-plan.md)
7. [Apply](03_07-apply.md)
8. [Exercícios](03_08-exercicios/)

## Próximo passo

Após o Módulo 3, siga para [Módulo 4 - Core Workflow P2](../04_modulo/README.md), onde veremos operações adicionais: destroy, import, console, state CLI, dependências.
