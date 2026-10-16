variable "aws_region" {
  description = "Region for the state bucket, ECR repository and IAM roles."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name; must match `project` in the environments."
  type        = string
  default     = "webapp"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,18}$", var.project))
    error_message = "project must be 2-19 chars: lowercase letters, digits and hyphens, starting with a letter."
  }
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the CI roles, as owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name."
  }
}

variable "environments" {
  description = "GitHub environment names that may apply and deploy."
  type        = list(string)
  default     = ["dev", "prod"]
}
