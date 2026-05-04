variable "project_id" {
  description = "ID do projeto GCP onde os recursos serão criados"
  type        = string
}

variable "region" {
  description = "Região GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona GCP"
  type        = string
  default     = "us-central1-a"
}

variable "instance_name" {
  description = "Nome da instância Compute Engine"
  type        = string
  default     = "terraform-instance"
}

variable "machine_type" {
  description = "Tipo de máquina da instância (ex: e2-micro, e2-medium)"
  type        = string
  default     = "e2-micro"
}

variable "tags" {
  description = "Tags de rede aplicadas à instância"
  type        = list(string)
  default     = []
}
