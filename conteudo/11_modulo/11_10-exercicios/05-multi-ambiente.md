# Exercício 05 - Pipeline multi-ambiente (dev, hml, prod)

## Objetivo

Evoluir o pipeline para rodar em 3 ambientes, com progressão controlada e approvals em prod.

## Tarefa

1. Organize o código:

   ```
   infra/
   ├── .gitlab-ci.yml
   ├── versions.tf
   ├── main.tf
   ├── variables.tf
   └── envs/
       ├── dev.tfvars
       ├── hml.tfvars
       └── prod.tfvars
   ```

2. No pipeline, crie 3 pares `plan_*` + `apply_*`:
   - `plan_dev` + `apply_dev` → automático após merge em main.
   - `plan_hml` + `apply_hml` → manual, depende de `apply_dev`.
   - `plan_prod` + `apply_prod` → manual, depende de `apply_hml`, environment `prod` protegida.
3. Cada par usa `TF_STATE_NAME` distinto e carrega `-var-file="envs/${TF_ENV}.tfvars"`.
4. Configure **Protected environments**: `prod` exige 1+ approval de maintainer.

## Verificação

- Merge em main dispara `apply_dev` (manual ou automático, a critério).
- `apply_hml` só fica disponível após `apply_dev` passar.
- `apply_prod` pede approval.
- Em **Deployments → Environments**, cada ambiente mostra seu histórico.

## Desafio extra

- Adicione `drift_check` agendado (Schedule) rodando `plan` em todos os 3 environments diariamente.
- Se detectar drift, envie webhook pro Slack / abra issue automaticamente.
