variable "name" {
  description = "Name for the cluster, service, task family and related resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC the tasks run in."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the tasks."
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group of the load balancer allowed to reach the tasks."
  type        = string
}

variable "target_group_arn" {
  description = "ALB target group the service registers tasks into."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (for request-count scaling)."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix (for request-count scaling)."
  type        = string
}

variable "container_image" {
  description = "Image for the first task definition revision. Later revisions come from the deploy pipeline."
  type        = string
}

variable "container_port" {
  description = "Port the application listens on."
  type        = number
  default     = 8000
}

variable "cpu" {
  description = "Task CPU units (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Task memory in MiB. Must be a valid Fargate pairing with cpu."
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "X86_64 or ARM64. ARM64 (Graviton) is roughly 20% cheaper if the image supports it."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "min_capacity" {
  description = "Minimum number of running tasks."
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of running tasks."
  type        = number
  default     = 4
}

variable "cpu_target_percent" {
  description = "Average CPU utilisation auto scaling aims for."
  type        = number
  default     = 60
}

variable "requests_per_target" {
  description = "ALB requests per task per minute auto scaling aims for."
  type        = number
  default     = 1000
}

variable "use_fargate_spot" {
  description = "Run tasks above the first one on Fargate Spot."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Allow `aws ecs execute-command` into running tasks (sessions are logged and encrypted)."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Plain environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Container env var name => Secrets Manager / SSM valueFrom reference."
  type        = map(string)
  default     = {}
}

variable "secret_arns" {
  description = "Secret ARNs the execution role may read (to inject var.secrets)."
  type        = list(string)
  default     = []
}

variable "task_role_policy_arns" {
  description = "Extra IAM policies for the application's task role."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "KMS key for log groups and ECS Exec sessions."
  type        = string
}

variable "log_retention_days" {
  description = "Retention for application logs."
  type        = number
  default     = 30
}
