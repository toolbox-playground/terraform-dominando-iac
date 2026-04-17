# Exercício 04 - Lab completo GCP

Repositório de exemplo didático para aprendizado do **Terraform com Google Cloud Platform**. Este lab provisiona um serviço **Cloud Run** em múltiplas regiões.

## O que você vai aprender

- Configurar o provider Google.
- Usar `count` para criar o mesmo recurso em várias regiões.
- Consumir variáveis do tipo `list`.
- Aplicar labels e usar `locals` para dados dinâmicos.

## Pré-requisitos

- Terraform instalado.
- [gcloud SDK](https://cloud.google.com/sdk/docs/install) instalado.
- Projeto GCP criado com billing habilitado.
- Service Account com permissão de Cloud Run Admin.
- Chave JSON da service account baixada (`gcp.json` na raiz do lab).

## Estrutura dos arquivos

- `versions.tf` — bloco `terraform` com `required_providers`.
- `provider.tf` — configuração do provider Google.
- `variable.tf` — variáveis (projeto, app, regiões, container).
- `main.tf` — recurso `google_cloud_run_v2_service`.
- `output.tf` — URLs e locations dos serviços criados.
- `backend.tf` — backend local.

## Como executar

### 1. Prepare as credenciais

Salve a chave da sua service account em `gcp.json` na raiz do lab.

**Linux/macOS:**

```bash
export GOOGLE_CREDENTIALS=$(cat gcp.json | jq -c)
export GOOGLE_APPLICATION_CREDENTIALS=gcp.json
```

**Windows PowerShell:**

```powershell
$jsonContent = Get-Content gcp.json | ConvertFrom-Json | ConvertTo-Json -Compress
$env:GOOGLE_CREDENTIALS = $jsonContent
```

### 2. Crie um `terraform.tfvars`

```hcl
project_id = "meu-projeto-gcp"
app_name   = "hello"
location   = ["us-central1", "southamerica-east1"]
container  = "gcr.io/google-samples/hello-app"
```

### 3. Execute o workflow

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform output
```

### 4. Verifique no console GCP

Acesse **Cloud Run** nas regiões listadas em `location` e veja os serviços criados.

### 5. Destrua os recursos

```bash
terraform destroy
```

## Referências

- [Provider Google](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Cloud Run v2 Resource](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service)
