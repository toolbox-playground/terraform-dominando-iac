# Exercício 04 - OIDC com AWS (sem chaves estáticas)

## Objetivo

Autenticar o pipeline na AWS via OIDC, eliminando `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` das variáveis.

## Tarefa

1. No console AWS ou via Terraform, crie:
   - Identity Provider OIDC apontando para `https://gitlab.com`.
   - IAM Role `gitlab-ci-terraform` com trust policy que aceite JWTs do seu projeto específico em branch `main`.
   - Policy aderente ao princípio do menor privilégio (para o lab, `AmazonS3FullAccess` basta).
2. No `.gitlab-ci.yml`, adicione:

   ```yaml
   .aws_oidc:
     id_tokens:
       AWS_ID_TOKEN:
         aud: https://gitlab.com
     before_script:
       - apk add --no-cache aws-cli jq
       - |
         CREDS=$(aws sts assume-role-with-web-identity \
           --role-arn $AWS_ROLE_ARN \
           --role-session-name gitlab-${CI_JOB_ID} \
           --web-identity-token $AWS_ID_TOKEN)
         export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r .Credentials.AccessKeyId)
         export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .Credentials.SecretAccessKey)
         export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r .Credentials.SessionToken)
       - aws sts get-caller-identity
   ```

3. Faça plan/apply herdarem de `.aws_oidc`.
4. Verifique no `get-caller-identity` que a role é a correta.

## Verificação

- `plan` e `apply` funcionam sem chaves estáticas.
- Remover `AWS_ACCESS_KEY_ID` das variáveis CI/CD e o pipeline continua passando.
- Criar um MR em branch qualquer (não `main`) — deve falhar por trust policy (se configurada com condição de ref).

## Desafio extra

- Restrinja a role: leitura em dev/hml, write só em prod (roles separadas).
- Use `gitlab.com:environment` no trust para exigir que o job esteja num environment protegido.
