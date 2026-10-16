data "aws_caller_identity" "current" {}

locals {
  image_repository = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project}"
}

# Dev favours low cost: one NAT gateway, Fargate Spot, small database,
# no deletion protection so the whole stack can be torn down at night.
module "app" {
  source = "../../stacks/web-app"

  project     = var.project
  environment = "dev"

  vpc_cidr                   = var.vpc_cidr
  az_count                   = 2
  single_nat_gateway         = true
  enable_interface_endpoints = false

  certificate_arn = var.certificate_arn
  enable_waf      = false

  container_image        = "${local.image_repository}:${var.initial_image_tag}"
  task_cpu               = 256
  task_memory            = 512
  min_tasks              = 1
  max_tasks              = 2
  use_fargate_spot       = true
  enable_execute_command = true
  log_retention_days     = 14

  db_instance_class        = "db.t4g.micro"
  db_allocated_storage     = 20
  db_multi_az              = false
  db_backup_retention_days = 1

  deletion_protection = false
  alarm_emails        = var.alarm_emails
}
