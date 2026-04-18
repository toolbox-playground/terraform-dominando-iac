variable "server_name" {
  description = "Nome do servidor"
  type        = string
  default     = "example.com"
}

locals {
  rendered_config = templatefile("${path.module}/config.tpl", {
    server_name = var.server_name
  })
}

output "config_rendered" {
  value = local.rendered_config
}
