# 07_05 - Dados Sensíveis no State

## O problema

State contém **tudo** que um provider retorna — inclusive valores sensíveis:

- Senhas de RDS, ElastiCache, Redis.
- Tokens de API gerados (ex.: webhook secrets).
- Private keys (TLS, SSH).
- Valores de `variable { sensitive = true }`.
- Outputs marcados como sensíveis (o valor **ainda está lá**).

Ou seja: **state é um segredo**. Qualquer pessoa com acesso ao backend tem acesso a esses valores.

## Camadas de proteção

### 1. Encryption at rest

- **S3**: `encrypt = true` no backend ou SSE habilitado no bucket (de preferência SSE-KMS).
- **GCS**: encryption automática; CMEK (KMS) opcional.
- **Azure Storage**: encryption automática; pode usar CMK.

### 2. Encryption in transit

Backends remotos usam HTTPS por padrão. Nunca desative TLS.

### 3. Access control

Princípio do menor privilégio:

- Apenas roles/SAs do Terraform podem ler/escrever.
- Devs individuais acessam indiretamente (via IAM assume role ou CI).
- Logs de auditoria obrigatórios.

### 4. Separação de states

Dados **muito** sensíveis podem viver em state próprio (ex.: segredos críticos num state separado com controle mais rígido).

## `sensitive = true` em variáveis

```hcl
variable "db_password" {
  type      = string
  sensitive = true
}
```

Efeito:

- Terraform **não exibe** o valor em plan/apply.
- Em outputs que usam essa var, o valor aparece como `(sensitive value)`.
- **Porém**: continua no state em texto claro.

## `sensitive = true` em outputs

```hcl
output "db_password" {
  value     = aws_db_instance.main.password
  sensitive = true
}
```

Idem: protege o **display**, não o **armazenamento**.

## Attributes computed marcados automaticamente

Alguns providers marcam atributos como `sensitive` automaticamente (ex.: `aws_db_instance.password`). Ao referenciá-los, o Terraform rastreia essa marcação e evita exibir.

Mas se você armazenar num `local` sem `sensitive`, a marca se perde em versões antigas — verifique a versão do Terraform.

## Alternativas: não deixe secrets no state

### 1. Gere o secret **fora** do Terraform

Use AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager. Terraform só cria a **referência** (ARN/URI), não o valor:

```hcl
data "aws_secretsmanager_secret_version" "db" {
  secret_id = "prod/db/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db.secret_string
}
```

O valor aparece no state como atributo do data source — **ainda está lá**, mas a rotação é feita por outra via.

### 2. Use `random_password` + store externo

```hcl
resource "random_password" "db" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "db" {
  name = "prod/db/password"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}

resource "aws_db_instance" "main" {
  password = random_password.db.result
}
```

A senha fica no state, mas a **fonte de verdade** é o Secrets Manager. Apps consultam lá.

### 3. Segredos gerenciados fora do Terraform

Para secrets ultra-críticos (assinaturas de CA, chaves mestras), não use Terraform para gerar — apenas referencie:

```hcl
resource "aws_iam_role_policy_attachment" "x" {
  # ... aponta para policy existente criada fora
}
```

## "Eu não quero que isso apareça no plan!"

Sensitive aplica-se ao **display**, não ao plan em si. O plan precisa saber o valor para planejar mudanças.

Se precisar ocultar totalmente, configure o CI para não imprimir plans em logs públicos e restrinja acesso aos artifacts.

## Exemplo de vazamento acidental

CI que imprime `terraform plan` em log público:

```
+ password = "P@ssw0rdQuaseCerto"
```

Bloqueios:

- `sensitive = true` no output → `password = (sensitive value)`.
- Provider-auto-sensitive → a maioria dos providers já marca.
- Log level: nunca rode com `TF_LOG=DEBUG` em CI público.
- Masked variables em CI/CD (GitLab "masked", GitHub "secret").

## Rotação de secrets

1. Gere nova senha (`random_password` ou Secrets Manager com rotação).
2. Aplique.
3. Cheque que a aplicação continua funcionando (referência ao secret atualiza sozinha se feita via data source).
4. Confirme que versão antiga não é mais necessária.

## Checklist de segurança

- [ ] Backend com encryption at rest (KMS preferível).
- [ ] Versioning habilitado para rollback.
- [ ] Access control mínimo por IAM/RBAC.
- [ ] Audit logging ativado.
- [ ] `sensitive = true` em todas as variáveis/outputs com segredo.
- [ ] Segredos críticos em Secrets Manager/Vault, não em tfvars.
- [ ] `.gitignore` bloqueia `*.tfvars`, `*.tfstate`, `.env`.
- [ ] CI mascara variáveis sensíveis nos logs.
- [ ] Rotação de credenciais tem processo definido.

Próximo tópico: **operações de state via CLI** — recap com foco em situações de state sensível.
