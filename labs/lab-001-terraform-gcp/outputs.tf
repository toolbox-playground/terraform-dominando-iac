output "instance_name" {
  description = "Nome da instância criada"
  value       = google_compute_instance.vm_instance.name
}

output "instance_ip" {
  description = "IP externo da instância"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "instance_zone" {
  description = "Zona onde a instância foi criada"
  value       = google_compute_instance.vm_instance.zone
}

output "machine_type" {
  description = "Tipo de máquina em uso"
  value       = google_compute_instance.vm_instance.machine_type
}
