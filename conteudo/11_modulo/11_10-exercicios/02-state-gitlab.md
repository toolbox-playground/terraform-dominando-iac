# Exercício 02 - State remoto no GitLab

## Objetivo

Configurar um projeto para usar o HTTP backend do GitLab como state remoto.

## Tarefa

1. No projeto do exercício 01, declare no código:

   ```hcl
   terraform {
     backend "http" {}
   }
   ```

2. Inicialize localmente usando PAT (escopo `api`):

   ```bash
   GITLAB_USER=seu.usuario
   GITLAB_TOKEN=glpat-xxxxx
   PROJECT_ID=<ID>
   STATE_NAME=dev

   TF_ADDRESS="https://gitlab.com/api/v4/projects/${PROJECT_ID}/terraform/state/${STATE_NAME}"

   terraform init \
     -backend-config="address=${TF_ADDRESS}" \
     -backend-config="lock_address=${TF_ADDRESS}/lock" \
     -backend-config="unlock_address=${TF_ADDRESS}/lock" \
     -backend-config="username=${GITLAB_USER}" \
     -backend-config="password=${GITLAB_TOKEN}" \
     -backend-config="lock_method=POST" \
     -backend-config="unlock_method=DELETE"
   ```

3. Aplique e verifique em **Infrastructure → Terraform states** que o state apareceu.
4. Adicione um segundo state (`STATE_NAME=hml`) e repita em outro diretório (ou workspace).

## Verificação

- `terraform state list` mostra recursos do projeto.
- GitLab UI exibe ambos os states.
- `terraform plan` detecta corretamente diffs (teste mudando algo).

## Desafio extra

- Force um cenário de lock: abra 2 terminais, rode `terraform plan` simultâneo — o segundo deve falhar.
- Use `terraform force-unlock` ou a UI para liberar.
