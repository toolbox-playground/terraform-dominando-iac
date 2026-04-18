# Exercício 06 - Publicar módulo na GitLab Terraform Registry

## Objetivo

Transformar o módulo criado no Módulo 10 num pacote versionado publicado automaticamente.

## Tarefa

1. Em um novo projeto GitLab (`terraform-aws-bucket-seguro`), coloque o módulo `bucket-seguro` do Módulo 10.
2. Adicione `.gitlab-ci.yml` com:
   - Validações (`fmt`, `validate`, `tflint`, `checkov`).
   - `plan` em `examples/basico/`.
   - `publish` rodando **apenas em tag `vX.Y.Z`**, enviando o tarball para o Terraform Module Registry via API.
   - `release` que cria um release no GitLab usando release-cli.
3. Commit + push.
4. Crie uma tag:

   ```bash
   git tag -a v1.0.0 -m "first release"
   git push --tags
   ```

5. Veja o pipeline publicar o módulo.
6. Em outro projeto consumidor, adicione:

   ```hcl
   module "bucket" {
     source  = "gitlab.com/<seu-grupo>/terraform-aws-bucket-seguro/aws"
     version = "1.0.0"

     nome     = "meu-bucket"
     ambiente = "dev"
   }
   ```

7. `terraform init` e valide o download da registry privada.

## Verificação

- Em **Deploy → Package Registry → Terraform modules**, o pacote aparece listado.
- Em **Releases**, a v1.0.0 aparece.
- O projeto consumidor consegue baixar e usar o módulo.

## Desafio extra

- Configure protected tags (`v*` só criáveis por maintainers).
- Adicione uma segunda versão (`v1.1.0`) e veja o consumidor subir de versão com `terraform init -upgrade`.
- Implemente semantic-release para versionar automaticamente baseado em conventional commits.
