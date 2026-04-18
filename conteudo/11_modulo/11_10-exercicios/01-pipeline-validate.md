# Exercício 01 - Pipeline de validação

## Objetivo

Criar o pipeline mínimo de validação em um repositório GitLab com código Terraform.

## Tarefa

1. Crie um projeto novo no GitLab (`meu-infra-lab`).
2. Adicione um `main.tf` simples com ao menos 2 recursos (pode ser `null_resource` se não quiser provisionar cloud).
3. Crie `.gitlab-ci.yml` com 4 jobs:
   - `fmt` (`terraform fmt -check -recursive`).
   - `validate` (`terraform init -backend=false` + `terraform validate`).
   - `tflint` (usando a imagem `ghcr.io/terraform-linters/tflint:latest`).
   - `checkov` (usando `bridgecrew/checkov:latest`).
4. Abra um MR com alguma mudança e observe os 4 jobs rodando.
5. **Propositalmente** introduza um erro (código mal formatado, recurso deprecated, bucket público) e veja qual job falha.

## Verificação

- Pipeline passa 100% sem erros propositais.
- Pipeline reprova corretamente quando você quebra algo.
- Configure **Settings → Merge requests → Pipelines must succeed** e tente mergear com pipeline vermelho — deve ser bloqueado.

## Desafio extra

- Adicione `terraform-docs` como job, gerando README automaticamente.
- Force o job a falhar se o README não estiver atualizado.
