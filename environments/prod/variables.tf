variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "project" {
  description = "Project name; must match the bootstrap stack (it names the ECR repository)."
  type        = string
}

variable "repository" {
  description = "Source repository, recorded in resource tags (set by CI from github.repository)."
  type        = string
  default     = "unknown"
}

variable "vpc_cidr" {
  description = "VPC CIDR for this environment."
  type        = string
}

variable "initial_image_tag" {
  description = "Image tag for the first task definition revision; later deploys come from CI."
  type        = string
  default     = "bootstrap"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (null = HTTP only)."
  type        = string
  default     = null
}

variable "alarm_emails" {
  description = "Who gets alarm emails."
  type        = list(string)
  default     = []
}
