variable "name" {
  description = "Name prefix for every resource in the module."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. The subnet layout assumes a /16."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.cidr_block)) && endswith(var.cidr_block, "/16")
    error_message = "cidr_block must be a valid /16, for example 10.20.0.0/16."
  }
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway for all AZs (cheaper, not AZ-fault-tolerant). Use false in prod."
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Create interface endpoints for ECR, CloudWatch Logs and Secrets Manager."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "KMS key used to encrypt the flow-log log group."
  type        = string
}

variable "flow_log_retention_days" {
  description = "Retention for VPC flow logs."
  type        = number
  default     = 30
}
