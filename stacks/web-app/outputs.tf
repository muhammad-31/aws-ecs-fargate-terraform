output "app_url" {
  description = "URL of the application."
  value       = "${var.certificate_arn == null ? "http" : "https"}://${module.alb.dns_name}"
}

output "alb_dns_name" {
  description = "Load balancer DNS name (point a CNAME or Route 53 alias here)."
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "Load balancer hosted zone ID for Route 53 alias records."
  value       = module.alb.zone_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name (used by the deploy workflow)."
  value       = module.service.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name (used by the deploy workflow)."
  value       = module.service.service_name
}

output "ecs_task_family" {
  description = "Task definition family (used by the deploy workflow)."
  value       = module.service.task_family
}

output "ecs_container_name" {
  description = "Container name inside the task definition."
  value       = module.service.container_name
}

output "log_group_name" {
  description = "CloudWatch log group with application logs."
  value       = module.service.log_group_name
}

output "db_address" {
  description = "Database endpoint hostname."
  value       = module.database.address
}

output "db_secret_arn" {
  description = "Secrets Manager ARN of the generated DB master credentials."
  value       = module.database.master_user_secret_arn
}

output "alarm_topic_arn" {
  description = "SNS topic for alarms; subscribe Slack/PagerDuty here."
  value       = module.alarms.sns_topic_arn
}

output "nat_public_ips" {
  description = "Outbound IPs of the service (for third-party allow-lists)."
  value       = module.network.nat_public_ips
}
