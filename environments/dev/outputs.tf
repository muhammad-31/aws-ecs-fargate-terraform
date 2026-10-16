output "app_url" {
  description = "Application URL."
  value       = module.app.app_url
}

output "alb_dns_name" {
  description = "Load balancer DNS name."
  value       = module.app.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster (deploy workflow input)."
  value       = module.app.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service (deploy workflow input)."
  value       = module.app.ecs_service_name
}

output "ecs_task_family" {
  description = "Task definition family (deploy workflow input)."
  value       = module.app.ecs_task_family
}

output "log_group_name" {
  description = "Application logs."
  value       = module.app.log_group_name
}

output "alarm_topic_arn" {
  description = "SNS topic for alarms."
  value       = module.app.alarm_topic_arn
}
