# Exercício 03 - Plan em MR e apply em main

## Objetivo

Implementar o fluxo completo: MR dispara `plan`, merge em `main` dispara `apply` manual.

## Tarefa

1. Incorpore o state remoto do exercício 02 no pipeline:
   - `plan` roda em MR e em push para main.
   - `apply` só em push para `main`, com `when: manual`.
   - `apply` depende de `plan` via `dependencies` e consome o `tfplan` artifact.
2. Adicione `reports.terraform: plan.json` para ver o widget na MR.
3. Abra uma MR que adicione 1 recurso, veja o plan no widget.
4. Mergeie e observe `apply` aguardando clique manual.

## Dicas

```yaml
plan:
  stage: plan
  script:
    - terraform init ...
    - terraform plan -out=tfplan -no-color | tee plan.txt
    - terraform show -json tfplan > plan.json
  artifacts:
    paths: [tfplan]
    reports:
      terraform: plan.json

apply:
  stage: apply
  script:
    - terraform init ...
    - terraform apply tfplan
  dependencies: [plan]
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  environment:
    name: dev
```

## Verificação

- MR mostra widget "Terraform" com contagem de +/- recursos.
- Merge em main exibe pipeline com `apply` bloqueado (botão play).
- Clicando no play, apply executa e registra em **Deployments → Environments**.

## Desafio extra

- Configure **Protected environments** para exigir approval antes do apply.
- Adicione um job `destroy` manual no mesmo pipeline (útil para labs).
