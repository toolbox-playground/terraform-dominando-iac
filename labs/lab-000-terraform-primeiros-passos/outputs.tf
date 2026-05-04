output "caminho_arquivo" {
  description = "Caminho completo do arquivo criado"
  value       = local_file.mensagem.filename
}

output "conteudo_arquivo" {
  description = "Conteúdo do arquivo criado"
  value       = local_file.mensagem.content
}
