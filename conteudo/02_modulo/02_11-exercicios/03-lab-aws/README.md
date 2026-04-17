# Exercício 03 - Lab completo AWS

Repositório de exemplo didático para aprendizado do **Terraform com AWS**. Este lab te leva do zero à criação de uma instância EC2 usando o ciclo completo do workflow WPC.

## O que você vai aprender

- Configurar o provider AWS.
- Estruturar um projeto com vários `.tf`.
- Usar variáveis do tipo `map` para escolher AMI por região.
- Executar o ciclo completo: `init → validate → plan → apply → destroy`.

## Pré-requisitos

- Terraform instalado (ver [02_08-instalacao](../../02_08-instalacao/02_08-instalacao.md)).
- Conta AWS com access key/secret.
- Permissões para criar EC2 na região escolhida.

## Estrutura dos arquivos

- `versions.tf` — bloco `terraform` com `required_providers`.
- `provider.tf` — configuração do provider AWS.
- `variables.tf` — variáveis (região e AMI).
- `instance.tf` — recurso `aws_instance`.
- `backend.tf` — backend local para o state.

## Como executar

### 1. Configure as credenciais AWS

**Linux/macOS:**

```bash
export AWS_ACCESS_KEY_ID="<sua_access_key>"
export AWS_SECRET_ACCESS_KEY="<seu_secret>"
export AWS_DEFAULT_REGION="us-west-2"
```

**Windows PowerShell:**

```powershell
$env:AWS_ACCESS_KEY_ID = "<sua_access_key>"
$env:AWS_SECRET_ACCESS_KEY = "<seu_secret>"
$env:AWS_DEFAULT_REGION = "us-west-2"
```

### 2. Execute o workflow completo

```bash
terraform init         # baixa o provider AWS
terraform fmt          # formata os arquivos
terraform validate     # valida a configuração
terraform plan         # revisa o que vai acontecer
terraform apply        # cria a instância (digite "yes" para confirmar)
```

### 3. Confirme no console da AWS

Acesse o console EC2 na região configurada e veja a instância `Toolbox-Playground-AWS-1`.

### 4. Destrua os recursos

Para evitar cobrança:

```bash
terraform destroy
```

## Referências

- Tópico [02_05 - Workflow WPC](../../02_05-workflow-wpc.md)
- [Provider AWS — authentication](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
