variable "name" {
  description = "Prefix for the SNS topic and alarm names."
  type        = string
}

variable "alarm_emails" {
  description = "Email addresses subscribed to alarm notifications (each must confirm by email)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the SNS topic."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name."
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name."
  type        = string
}

variable "db_instance_identifier" {
  description = "RDS instance identifier."
  type        = string
}

variable "alb_5xx_threshold" {
  description = "ALB-generated 5xx per minute that trigger an alarm."
  type        = number
  default     = 5
}

variable "target_5xx_threshold" {
  description = "Application 5xx per minute that trigger an alarm."
  type        = number
  default     = 5
}

variable "latency_p95_seconds" {
  description = "p95 target response time (seconds) that triggers an alarm."
  type        = number
  default     = 1
}
