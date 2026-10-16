output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.this.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.this.name
}

output "task_family" {
  description = "Task definition family; the deploy pipeline registers new revisions in it."
  value       = aws_ecs_task_definition.this.family
}

output "container_name" {
  description = "Name of the application container in the task definition."
  value       = local.container_name
}

output "task_security_group_id" {
  description = "Security group of the tasks (grant it access to databases, caches, etc.)."
  value       = aws_security_group.task.id
}

output "execution_role_arn" {
  description = "Task execution role ARN."
  value       = aws_iam_role.execution.arn
}

output "task_role_arn" {
  description = "Task (application) role ARN."
  value       = aws_iam_role.task.arn
}

output "log_group_name" {
  description = "CloudWatch log group with application logs."
  value       = aws_cloudwatch_log_group.app.name
}
