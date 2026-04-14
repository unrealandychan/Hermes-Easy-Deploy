output "public_ip" {
  description = "Public IP address of the Hermes instance"
  value       = google_compute_instance.hermes.network_interface[0].access_config[0].nat_ip
}

output "instance_id" {
  description = "Instance name"
  value       = google_compute_instance.hermes.name
}

output "ssh_command" {
  description = "gcloud SSH command (recommended)"
  value       = "gcloud compute ssh ${google_compute_instance.hermes.name} --zone ${var.zone} --project ${var.project_id}"
}

output "gateway_url" {
  description = "Hermes gateway URL"
  value       = "http://${google_compute_instance.hermes.network_interface[0].access_config[0].nat_ip}:8080"
}
