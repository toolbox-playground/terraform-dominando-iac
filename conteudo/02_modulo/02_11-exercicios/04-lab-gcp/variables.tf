variable "project_id" {
  description = "ID do projeto Google Cloud"
  type        = string
}

variable "app_name" {
  description = "Nome do serviço Cloud Run"
  type        = string
}

variable "location" {
  description = "Lista de regiões onde o serviço será criado"
  type        = list(string)
}

variable "container" {
  description = "Imagem do container a ser deployada"
  type        = string
}

variable "container_port_name" {
  description = "Nome da porta do container"
  type        = string
  default     = "h2c"
}

variable "container_port" {
  description = "Porta do container"
  type        = number
  default     = 8080
}

variable "resource_cpu" {
  description = "CPU limite do Cloud Run"
  type        = string
  default     = "1000m"
}

variable "resource_memory" {
  description = "Memória limite do Cloud Run"
  type        = string
  default     = "512Mi"
}

variable "label_environment" {
  type    = string
  default = "dev"
}

variable "label_cost_center" {
  type    = string
  default = "devops"
}

variable "label_responsible" {
  type    = string
  default = "someone"
}

variable "label_creator" {
  type    = string
  default = "pipeline"
}
