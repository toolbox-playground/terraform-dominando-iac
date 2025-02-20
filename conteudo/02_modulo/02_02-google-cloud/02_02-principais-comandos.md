# 02_02 - Exercício Criando sua Primeira Infraestrutura com Terraform

## Objetivo
Demonstrar a infraestrutura como código criando um recurso simples na nuvem.  

### Passos
1. Crie um Arquivo de Configuração:
No mesmo diretório, crie um arquivo chamado main.tf.  
Adicione um recurso simples (por exemplo, um bucket do S3 da AWS):  
```hcl
resource "aws_s3_bucket" "meu_bucket" {
  bucket = "meu-primeiro-bucket-terraform"
  acl    = "private"
}
```

2. Execute os comandos do Workflow do Terraform:
```bash
# Formatação do código
terraform fmt

# Validação do código
terraform validate

# Pré-visualização das mudanças
terraform plan

# Aplicação das mudanças
terraform apply
```

3. Verifique a Infraestrutura:
- Confirme se o recurso foi criado usando a interface web do provedor ou o CLI (exemplo: aws s3 ls).  
