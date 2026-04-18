# Módulo 5 - HCL: HashiCorp Configuration Language

HCL é a linguagem em que você escreve Terraform. Neste módulo, você aprende a dominar os fundamentos: sintaxe, tipos, operadores, expressões, strings e templates.

## Objetivos de aprendizagem

- Entender o papel do HCL no ecossistema HashiCorp.
- Conhecer a sintaxe básica: blocos, atributos, labels, comentários.
- Distinguir tipos primitivos (`string`, `number`, `bool`) dos complexos (`list`, `set`, `map`, `tuple`, `object`).
- Usar operadores aritméticos, lógicos, de comparação e o ternário.
- Escrever expressões `for`, splat `[*]` e referências.
- Manipular strings com interpolação, heredoc, diretivas e `templatefile`.
- Reconhecer a alternativa JSON (`.tf.json`).
- Ler e escrever projetos completos com HCL bem estruturado.

## Tópicos

1. [O que é HCL](05_01-o-que-e-hcl.md)
2. [Sintaxe básica](05_02-sintaxe-basica.md)
3. [Tipos primitivos](05_03-tipos-primitivos.md)
4. [Tipos complexos](05_04-tipos-complexos.md)
5. [Operadores e expressões](05_05-operadores-expressoes.md)
6. [Strings e templating](05_06-strings-templating.md)
7. [JSON como alternativa](05_07-json-alternativa.md)
8. [Exemplo completo comentado](05_08-exemplo-completo.md)
9. [Exercícios](05_09-exercicios/)

## Pré-requisitos

- Módulos 1 a 4 concluídos.
- Ambiente Terraform configurado com um provider (AWS ou GCP).

## Próximo passo

No Módulo 6, aprofundamos **providers**: como declarar, configurar, autenticar, usar aliases e gerenciar versões.
