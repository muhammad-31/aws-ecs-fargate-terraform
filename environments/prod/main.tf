data "aws_caller_identity" "current" {}

locals {
  image_repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}"
}

# Prod favours resilience: three AZs, NAT gateway per AZ, Multi-AZ database,
# HTTPS + WAF, deletion protection, private AWS API access via endpoints.
module "app" {
  source = "../../stacks/web-app"

  project     = var.project
  environment = "prod"

  vpc_cidr                   = var.vpc_cidr
  az_count                   = 3
  single_nat_gateway         = false
  enable_interface_endpoints = true

  certificate_arn = var.certificate_arn
  enable_waf      = true

  container_image        = "${local.image_repository}:${var.initial_image_tag}"
  task_cpu               = 512
  task_memory            = 1024
  min_tasks              = 2
  max_tasks              = 10
  use_fargate_spot       = false
  enable_execute_command = false
  log_retention_days     = 90

  db_instance_class        = "db.t4g.medium"
  db_allocated_storage     = 50
  db_multi_az              = true
  db_backup_retention_days = 14

  deletion_protection = true
  alarm_emails        = var.alarm_emails
}

check "prod_uses_https" {
  assert {
    condition     = var.certificate_arn != null
    error_message = "Prod should run with an ACM certificate (certificate_arn); it is currently serving plain HTTP."
  }
}
