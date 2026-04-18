# Módulo 11 - GitLab CI/CD para Terraform

Terraform sozinho é poderoso; Terraform + CI/CD é uma plataforma de infraestrutura. Este módulo constrói, do zero, pipelines GitLab que entregam segurança, revisão e auditoria para suas mudanças de infra.

## Objetivos de aprendizagem

- Entender **por que** `apply` local não escala.
- Dominar conceitos do GitLab CI/CD (stages, rules, artifacts, environments).
- Configurar state remoto via HTTP backend nativo do GitLab.
- Gerar plans revisáveis em MR, com bloqueio de merge se pipeline falhar.
- Autenticar na cloud via OIDC (sem chaves estáticas).
- Criar pipelines multi-ambiente com approvals em produção.
- Publicar módulos reutilizáveis na Terraform Module Registry do GitLab.
- Aplicar boas práticas de segurança e operação.

## Tópicos

1. [Por que CI/CD](11_01-por-que-ci-cd.md)
2. [Conceitos de GitLab CI/CD](11_02-conceitos-gitlab-ci.md)
3. [Pipeline de validação](11_03-pipeline-validate.md)
4. [State remoto no GitLab (HTTP backend)](11_04-state-remoto-gitlab.md)
5. [Plan em MR com revisão](11_05-pipeline-plan-mr.md)
6. [OIDC e credenciais efêmeras](11_06-oidc-e-credenciais.md)
7. [Apply, environments e approvals](11_07-pipeline-apply-environments.md)
8. [Pipeline de módulos e release automático](11_08-pipeline-modulos.md)
9. [Boas práticas e armadilhas](11_09-boas-praticas.md)
10. [Exercícios](11_10-exercicios/)

## Filosofia

> "Se algo não pode ser feito pelo pipeline, então não deveria ser feito."

Todo apply em prod passa por CI. Todo segredo é efêmero. Toda mudança é revisada. Toda falha é observável. Isso é o estado da arte — e é atingível com ferramentas gratuitas.

## Após o curso

Você terá base para:

- Evoluir para Atlantis ou Spacelift se quiser UI mais rica.
- Integrar com Vault para secrets dinâmicos.
- Aplicar o mesmo padrão em GitHub Actions, CircleCI, Jenkins.
- Montar plataformas internas de auto-service de infra.
- Ensinar o resto do seu time.

Parabéns por ter chegado até aqui. Bom provisionamento.
