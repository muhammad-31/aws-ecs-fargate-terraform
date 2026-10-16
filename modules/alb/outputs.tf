output "dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "Route 53 hosted zone ID of the load balancer (for alias records)."
  value       = aws_lb.this.zone_id
}

output "security_group_id" {
  description = "Security group attached to the load balancer."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "Target group the ECS service registers into."
  value       = aws_lb_target_group.app.arn
}

output "arn_suffix" {
  description = "ALB ARN suffix, used for CloudWatch metrics and request-count scaling."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix, used for CloudWatch metrics."
  value       = aws_lb_target_group.app.arn_suffix
}

output "https_listener_arn" {
  description = "HTTPS listener ARN, or null when no certificate is configured."
  value       = try(aws_lb_listener.https[0].arn, null)
}
