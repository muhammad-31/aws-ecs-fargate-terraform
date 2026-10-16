variable "project" {
  description = "Short project name used as a prefix (lowercase letters, digits, hyphens)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}$", var.project))
    error_message = "project must be 2-19 chars: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

# --- network ---------------------------------------------------------------

variable "vpc_cidr" {
  description = "VPC CIDR (/16). Use a different range per environment so they can be peered later."
  type        = string
}

variable "az_count" {
  description = "Availability zones to use (2 or 3)."
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Share one NAT gateway across AZs (cheaper, less resilient)."
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Create interface VPC endpoints for ECR, Logs and Secrets Manager."
  type        = bool
  default     = false
}

# --- edge ------------------------------------------------------------------

variable "certificate_arn" {
  description = "ACM certificate for HTTPS. null = HTTP only (dev)."
  type        = string
  default     = null
}

variable "enable_waf" {
  description = "Attach AWS WAF with managed rules to the load balancer."
  type        = bool
  default     = true
}

# --- service ---------------------------------------------------------------

variable "container_image" {
  description = "Image for the initial task definition revision."
  type        = string
}

variable "container_port" {
  description = "Port the application listens on."
  type        = number
  default     = 8000
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory (MiB)."
  type        = number
  default     = 512
}

variable "min_tasks" {
  description = "Minimum running tasks."
  type        = number
  default     = 1
}

variable "max_tasks" {
  description = "Maximum running tasks."
  type        = number
  default     = 4
}

variable "use_fargate_spot" {
  description = "Run tasks above the first on Fargate Spot."
  type        = bool
  default     = false
}

variable "enable_execute_command" {
  description = "Allow ECS Exec into running tasks."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Application log retention."
  type        = number
  default     = 30
}

# --- database --------------------------------------------------------------

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial DB storage (GiB)."
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Run a standby replica in another AZ."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Automated backup retention."
  type        = number
  default     = 7
}

# --- safety / ops ----------------------------------------------------------

variable "deletion_protection" {
  description = "Protect ALB and RDS from deletion; keep a final DB snapshot."
  type        = bool
  default     = true
}

variable "alarm_emails" {
  description = "Emails that receive alarm notifications."
  type        = list(string)
  default     = []
}
