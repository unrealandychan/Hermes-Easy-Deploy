output "public_ip" {
  description = "Public IP address of the Hermes instance"
  value       = aws_instance.hermes.public_ip
}

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.hermes.id
}

output "ssh_command" {
  description = "Direct SSH command"
  value       = "ssh -i <your-key.pem> ubuntu@${aws_instance.hermes.public_ip}"
}

output "ssm_command" {
  description = "AWS SSM Session Manager command (no open SSH port needed)"
  value       = "aws ssm start-session --target ${aws_instance.hermes.id} --region ${var.aws_region}"
}

output "gateway_url" {
  description = "Hermes gateway URL"
  value       = "http://${aws_instance.hermes.public_ip}:8080"
}
