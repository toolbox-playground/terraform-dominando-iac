# 02_01 - Configurando o Terraform

## Objetivo
Garantir que consigamos instalar e configurar corretamente o Terraform no ambiente local.  

### Passos
1.	Instale o Terraform:  
Siga a documentação oficial para instalar o Terraform no seu sistema operacional.  

Confirme a instalação executando:  
```bash
terraform version
```

2. Configure um Provider
Crie um arquivo **provider.tf** e defina o provedor da GCP
Exemplo de configuração:
```hcl
provider "google" {
  # Replace `PROJECT_ID` with your project
  project = var.project_id
}
```

Valide a configuração com:
```hcl
terraform validate
```

3. Execute o Terraform INIT:  
- Rode terraform init para inicializar o ambiente.  



