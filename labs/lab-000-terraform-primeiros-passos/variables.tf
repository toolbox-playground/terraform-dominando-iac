variable "mensagem" {
  description = "Conteúdo do arquivo a ser criado pelo Terraform"
  type        = string
  default     = "Olá, Terraform!"
}

variable "nome_arquivo" {
  description = "Nome do arquivo a ser criado"
  type        = string
  default     = "hello.txt"
}
