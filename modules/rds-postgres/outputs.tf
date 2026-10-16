output "address" {
  description = "Hostname of the database endpoint."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Database port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "identifier" {
  description = "DB instance identifier (for CloudWatch metrics)."
  value       = aws_db_instance.this.identifier
}

output "security_group_id" {
  description = "Security group of the database."
  value       = aws_security_group.db.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the generated master credentials."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
