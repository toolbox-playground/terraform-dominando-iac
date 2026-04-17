output "service_url" {
  description = "URLs em que os serviços Cloud Run estão disponíveis"
  value       = google_cloud_run_v2_service.default[*].traffic_statuses[*].uri
}

output "locations" {
  description = "Regiões onde os serviços foram criados"
  value       = google_cloud_run_v2_service.default[*].location
}
