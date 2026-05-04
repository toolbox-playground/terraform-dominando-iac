terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

resource "local_file" "mensagem" {
  content  = var.mensagem
  filename = "${path.module}/output/${var.nome_arquivo}"
}
