# Exercício 02 - State, Git e boas práticas

*(Integra `exercicios/2_intermediarios/15.md` - Relação do State com o Git.)*

## Objetivo

Garantir que state sensível jamais seja comitado e documentar boas práticas no repo.

## Tarefas

1. Crie um `.gitignore` na raiz do projeto com, no mínimo:

   ```gitignore
   # Terraform
   *.tfstate
   *.tfstate.*
   crash.log
   crash.*.log

   # Variáveis com segredos
   *.tfvars
   *.tfvars.json
   !example.tfvars.json

   # Diretório de cache
   .terraform/
   .terraform.tfstate*

   # Override files
   override.tf
   override.tf.json
   *_override.tf
   *_override.tf.json

   # Lock file (commit!)
   !.terraform.lock.hcl
   ```

2. Dentro do repo, tente:
   ```bash
   git status
   terraform apply
   git status
   ```
   Confirme que nenhum `*.tfstate` aparece como candidato a commit.

3. Adicione um `example.tfvars.json` no repo como template, sem valores sensíveis.

4. Configure um **pre-commit hook** (script em `.git/hooks/pre-commit`):

   ```bash
   #!/bin/bash
   if git diff --cached --name-only | grep -E '\.(tfstate|tfvars)$' | grep -v example; then
     echo "ERRO: state ou tfvars detectado no commit. Abortando."
     exit 1
   fi
   ```

   Torne executável com `chmod +x`.

5. Teste:
   ```bash
   git add terraform.tfstate  # git não bloqueia por .gitignore se forçado
   git commit -m "teste"      # hook deve barrar
   ```

## Documentação

No `README.md` do projeto, adicione uma seção **"Segurança do State"**:

- Nunca comitar arquivos `*.tfstate` ou `*.tfvars` com dados reais.
- Usar backend remoto com lock e criptografia.
- Rotacionar credenciais periodicamente.
- Auditar acesso ao bucket.

## Perguntas

1. Por que o `.terraform.lock.hcl` **deve** ser comitado (exceção do `.gitignore`)?
2. Se um colega já comitou `terraform.tfstate` antes do `.gitignore`, o que fazer? (Pista: `git rm --cached`, histórico reescrito se sensível)
3. Para secrets que **precisam** ser passados ao Terraform, onde armazenar se não for em `.tfvars`? (Pista: variáveis de ambiente, Vault, Secrets Manager)
