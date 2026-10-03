output "endpoint" {
  description = "Database hostname"
  value       = aws_db_instance.this.address
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret with connection details"
  value       = aws_secretsmanager_secret.db.arn
}

output "secret_name" {
  description = "Name of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db.name
}
