variable "name" {
  description = "Identifier for the DB instance and related resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC of the database."
  type        = string
}

variable "subnet_ids" {
  description = "Isolated data subnets (at least two AZs)."
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "Security groups allowed to connect on 5432, as name => security group ID (e.g. { ecs_service = sg-... })."
  type        = map(string)
  default     = {}
}

variable "engine_version" {
  description = "PostgreSQL version. A major version only (\"17\") lets RDS pick the latest minor."
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "DB instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "database_name" {
  description = "Name of the initial database."
  type        = string
  default     = "app"
}

variable "master_username" {
  description = "Master username. The password is generated and managed by RDS."
  type        = string
  default     = "app_admin"
}

variable "allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Upper bound for storage autoscaling in GiB."
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Run a synchronous standby in a second AZ."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days of automated backups (point-in-time recovery window)."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Block deletion and take a final snapshot on destroy."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply modifications now instead of in the maintenance window."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds (0 disables it)."
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights (not supported on every instance class)."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key for storage and Performance Insights encryption."
  type        = string
}
