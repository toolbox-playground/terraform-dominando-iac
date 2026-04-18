# Módulo 1 - Nivelamento

Este módulo estabelece a base conceitual para o resto do curso. Antes de escrever uma linha de Terraform, é essencial entender **o que é infraestrutura como código**, **por que queremos ir nessa direção** e **quais princípios** tornam a prática sustentável.

## Objetivos de aprendizagem

Ao final deste módulo, você será capaz de:

- Explicar o que é IaC e diferenciá-lo de ClickOps e scripts imperativos.
- Identificar as diferenças entre infraestrutura mutável e imutável, e saber quando cada uma é apropriada.
- Entender o conceito de idempotência e como o Terraform o garante.
- Reconhecer toil no seu dia a dia e argumentar pela sua eliminação via IaC.

## Tópicos

1. [Infraestrutura como Código (IaC)](01_01-infraestrutura-como-codigo.md)
2. [Infraestrutura Mutável](01_02-infraestrutura-mutavel.md)
3. [Infraestrutura Imutável](01_03-infraestrutura-imutavel.md)
4. [Idempotência](01_04-idempotencia.md)
5. [Toil](01_05-toil.md)

## Por que esses tópicos juntos?

Os cinco temas não são independentes. Eles se sustentam:

- **IaC** é o modelo mental e a prática.
- **Imutabilidade** é uma arquitetura que se casa perfeitamente com IaC (fica muito mais fácil gerenciar "criar/destruir" do que "modificar em produção").
- **Idempotência** é o mecanismo técnico que permite ao Terraform operar IaC com segurança.
- **Toil** é o problema que você elimina quando aplica os três conceitos anteriores de forma consistente.

Entender essa conexão é o que separa quem "sabe comandos do Terraform" de quem **faz engenharia de plataforma** com Terraform.
