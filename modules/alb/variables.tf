variable "name" {
  description = "Name prefix. Keep it short: ALB and target group names max out at 32 characters."
  type        = string

  validation {
    condition     = length(var.name) <= 28
    error_message = "name must be 28 characters or fewer so derived ALB/target group names stay valid."
  }
}

variable "vpc_id" {
  description = "VPC to place the load balancer in."
  type        = string
}

variable "vpc_cidr_block" {
  description = "VPC CIDR, used to scope ALB egress to the targets."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnets for the load balancer (at least two AZs)."
  type        = list(string)
}

variable "target_port" {
  description = "Port the application container listens on."
  type        = number
}

variable "health_check_path" {
  description = "HTTP path the target group uses for health checks."
  type        = string
  default     = "/healthz"
}

variable "certificate_arn" {
  description = "ACM certificate ARN. When null the ALB serves plain HTTP (dev only)."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protect the load balancer from deletion."
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Attach a WAFv2 web ACL with AWS managed rules and an IP rate limit."
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Max requests per 5-minute window per client IP before WAF blocks it."
  type        = number
  default     = 2000
}

variable "access_log_retention_days" {
  description = "Days to keep ALB access logs."
  type        = number
  default     = 30
}

variable "force_destroy_logs" {
  description = "Allow terraform destroy to delete a non-empty access-log bucket."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key that encrypts the WAF log group."
  type        = string
}
