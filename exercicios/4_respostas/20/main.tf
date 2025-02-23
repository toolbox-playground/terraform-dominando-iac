terraform {
  required_version = ">= 0.12"
}

# Para este exemplo, usaremos o provider "null", que permite demonstrar a ideia sem depender de um provedor real.
provider "null" {}

# Definindo variáveis locais com base no workspace atual.
locals {
  # Captura o nome do workspace atual (dev, staging, prod ou default)
  environment = terraform.workspace
  
  # Define um "instance_type" fictício com base no ambiente.
  instance_type = (
    local.environment == "prod"    ? "t3.large"  :
    local.environment == "staging" ? "t3.medium" :
                                   "t3.micro"
  )
}

# Um recurso fictício para demonstrar a aplicação das configurações.
resource "null_resource" "env_info" {
  # Usamos "triggers" para forçar a recriação se o ambiente mudar.
  triggers = {
    workspace     = local.environment
    instance_type = local.instance_type
  }
}

# Exibe os valores do ambiente e do tipo de instância
output "environment" {
  value = local.environment
}

output "instance_type" {
  value = local.instance_type
}
