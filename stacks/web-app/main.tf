# Composes the modules into one deployable environment. Each folder under
# environments/ calls this stack with its own sizing and safety settings, so
# dev and prod differ only in tfvars, never in code.

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name = "${var.project}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Encryption key for logs, SNS, RDS storage and ECS Exec
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "kms" {
  #checkov:skip=CKV_AWS_109:Key policies must grant the account root kms:*; access is then narrowed by IAM.
  #checkov:skip=CKV_AWS_111:Same as above; resource "*" in a key policy means "this key".
  #checkov:skip=CKV_AWS_356:Same as above.
  statement {
    sid       = "AccountAdministration"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "CloudWatchLogs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
    }
  }

  # CloudWatch alarms publish to the encrypted SNS topic.
  statement {
    sid       = "CloudWatchAlarmsToSns"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey*"]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "this" {
  description             = "${local.name} application data and logs"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.kms.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name}"
  target_key_id = aws_kms_key.this.key_id
}

# ---------------------------------------------------------------------------
# Building blocks
# ---------------------------------------------------------------------------

module "network" {
  source = "../../modules/network"

  name                       = local.name
  cidr_block                 = var.vpc_cidr
  az_count                   = var.az_count
  single_nat_gateway         = var.single_nat_gateway
  enable_interface_endpoints = var.enable_interface_endpoints
  kms_key_arn                = aws_kms_key.this.arn
}

module "alb" {
  source = "../../modules/alb"

  name                = local.name
  vpc_id              = module.network.vpc_id
  vpc_cidr_block      = module.network.vpc_cidr_block
  public_subnet_ids   = module.network.public_subnet_ids
  target_port         = var.container_port
  certificate_arn     = var.certificate_arn
  deletion_protection = var.deletion_protection
  enable_waf          = var.enable_waf
  force_destroy_logs  = !var.deletion_protection
  kms_key_arn         = aws_kms_key.this.arn
}

module "database" {
  source = "../../modules/rds-postgres"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.data_subnet_ids
  allowed_security_groups = { ecs_service = module.service.task_security_group_id }
  instance_class          = var.db_instance_class
  allocated_storage       = var.db_allocated_storage
  multi_az                = var.db_multi_az
  backup_retention_days   = var.db_backup_retention_days
  deletion_protection     = var.deletion_protection
  log_retention_days      = var.log_retention_days
  kms_key_arn             = aws_kms_key.this.arn
}

module "service" {
  source = "../../modules/ecs-service"

  name                    = local.name
  vpc_id                  = module.network.vpc_id
  subnet_ids              = module.network.app_subnet_ids
  alb_security_group_id   = module.alb.security_group_id
  target_group_arn        = module.alb.target_group_arn
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  container_image        = var.container_image
  container_port         = var.container_port
  cpu                    = var.task_cpu
  memory                 = var.task_memory
  min_capacity           = var.min_tasks
  max_capacity           = var.max_tasks
  use_fargate_spot       = var.use_fargate_spot
  enable_execute_command = var.enable_execute_command
  kms_key_arn            = aws_kms_key.this.arn
  log_retention_days     = var.log_retention_days

  environment_variables = {
    APP_ENV     = var.environment
    DB_HOST     = module.database.address
    DB_PORT     = tostring(module.database.port)
    DB_NAME     = module.database.database_name
    DB_SSLMODE  = "require"
    LOG_LEVEL   = var.environment == "prod" ? "info" : "debug"
    APP_VERSION = "bootstrap"
  }

  # ECS reads single JSON keys out of the RDS-managed secret at task start.
  secrets = {
    DB_USER     = "${module.database.master_user_secret_arn}:username::"
    DB_PASSWORD = "${module.database.master_user_secret_arn}:password::"
  }
  secret_arns = [module.database.master_user_secret_arn]
}

# Tasks may open connections to the database security group, nothing wider.
resource "aws_vpc_security_group_egress_rule" "service_to_db" {
  security_group_id            = module.service.task_security_group_id
  description                  = "PostgreSQL to the application database"
  referenced_security_group_id = module.database.security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

module "alarms" {
  source = "../../modules/alarms"

  name                    = local.name
  alarm_emails            = var.alarm_emails
  kms_key_arn             = aws_kms_key.this.arn
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  ecs_cluster_name        = module.service.cluster_name
  ecs_service_name        = module.service.service_name
  db_instance_identifier  = module.database.identifier
}
