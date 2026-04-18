![Terraform](imgs/logo_curso.jpg "Terraform - Dominando IAC")

# Terraform - Dominando Infraestrutura como Código

Bem-vindo ao repositório oficial do curso de Terraform da Toolbox, onde transformamos o aprendizado em prática real!

## Nosso objetivo

Este treinamento intensivo, com cerca de 30 horas divididas em 5 encontros ao vivo, foi projetado para que você domine o Terraform, uma das ferramentas mais poderosas e indispensáveis para infraestrutura de TI. Nossa missão é garantir que até mesmo iniciantes absolutos possam adquirir conhecimento e praticar o uso de Terraform de forma confiante e eficaz.

A combinação de teoria e prática vai prepará-lo para os desafios do dia a dia, tornando o aprendizado envolvente e aplicável.

## Ementa do Curso

| # | Módulo | Foco |
|---|--------|------|
| [1](conteudo/01_modulo/) | Nivelamento | IaC, mutable vs. immutable, idempotência, toil |
| [2](conteudo/02_modulo/) | Introdução ao Terraform | O que é, arquitetura, instalação, primeiro apply |
| [3](conteudo/03_modulo/) | Terraform Core Workflow | `init`, `fmt`, `validate`, `plan`, `apply` |
| [4](conteudo/04_modulo/) | Core Workflow P2 | `destroy`, dependências, `taint`/`-replace`, `import`, provisioners |
| [5](conteudo/05_modulo/) | HCL | Sintaxe, tipos, expressões, templating, JSON |
| [6](conteudo/06_modulo/) | Providers | `required_providers`, aliases, autenticação, Registry, data sources |
| [7](conteudo/07_modulo/) | State | Local vs. remoto, backends, locking, dados sensíveis, operações |
| [8](conteudo/08_modulo/) | Environments | Variables, locals, outputs, workspaces, tfvars, multi-ambiente |
| [9](conteudo/09_modulo/) | HCL Avançado | `count`, `for_each`, splat, `dynamic`, `lifecycle`, templates, funções |
| [10](conteudo/10_modulo/) | Módulos | Criação, inputs/outputs, versionamento, composição, publicação |
| [11](conteudo/11_modulo/) | GitLab CI/CD | Pipelines, state remoto, OIDC, multi-ambiente, release de módulos |

Cada módulo contém:

- **Tópicos teóricos** numerados (`NN_XX-nome.md`).
- **Pasta de exercícios** com tarefas práticas.
- **Pasta `respostas/`** quando aplicável, com soluções de referência.

## Estrutura do repositório

```
.
├── README.md
├── conteudo/               # Módulos 1 a 11, cada um com teoria + exercícios
│   ├── 01_modulo/
│   ├── 02_modulo/
│   └── ...
├── desafios/               # Desafios integradores (projeto final)
│   └── turma-01/
│       └── desafio.md
└── imgs/                   # Assets
```

## Desafio final

Ao fim do curso, você estará apto a resolver o desafio integrador em [`desafios/turma-01/desafio.md`](desafios/turma-01/desafio.md): provisionar uma aplicação web altamente disponível na AWS (VPC multi-AZ, ALB, Auto Scaling Group, RDS Multi-AZ, S3, CloudWatch) **com pipeline GitLab CI/CD** para plan/apply.

## Dinâmica das aulas

- **Turmas exclusivas**: Ambiente focado e interação direta com os especialistas.
- **Plano personalizado**: Adaptação ao seu nível de conhecimento e objetivos.
- **Conteúdos exclusivos**: Material de alta qualidade desenvolvido pela Toolbox.

## Público-alvo

Este curso é ideal para:

- **Programadores**: Que desejam se destacar no mercado ao dominar práticas de DevOps.
- **Profissionais de DevOps**: Interessados em se atualizar e aprofundar seus conhecimentos com as melhores práticas.
- **Especialistas em suporte, cloud, infra e redes**: Que desejam migrar ou evoluir na área de DevOps, adquirindo as habilidades essenciais para impulsionar suas carreiras.

## Como participar

Inscreva-se agora mesmo. Entre em contato com nosso time comercial pelo e-mail *contato@tbxtech.com* ou envie uma mensagem no WhatsApp (19) 9 8199-0082.

## Comunidade

Entre na nossa [comunidade do Discord — Toolbox Playground](https://discord.gg/XP8kQvpW).
