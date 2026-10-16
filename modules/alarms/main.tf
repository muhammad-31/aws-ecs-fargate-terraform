resource "aws_sns_topic" "alarms" {
  name              = "${var.name}-alarms"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.alarm_emails)

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = each.value
}

locals {
  actions = [aws_sns_topic.alarms.arn]

  # One place to read every alarm: what it watches and when it fires.
  alarms = {
    alb-5xx = {
      description = "Load balancer returned 5xx responses (ALB itself or no healthy targets)."
      namespace   = "AWS/ApplicationELB"
      metric      = "HTTPCode_ELB_5XX_Count"
      statistic   = "Sum"
      extended    = null
      threshold   = var.alb_5xx_threshold
      comparison  = "GreaterThanThreshold"
      periods     = 2
      dimensions  = { LoadBalancer = var.alb_arn_suffix }
    }
    target-5xx = {
      description = "Application returned 5xx responses."
      namespace   = "AWS/ApplicationELB"
      metric      = "HTTPCode_Target_5XX_Count"
      statistic   = "Sum"
      extended    = null
      threshold   = var.target_5xx_threshold
      comparison  = "GreaterThanThreshold"
      periods     = 2
      dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
    }
    unhealthy-targets = {
      description = "At least one task is failing ALB health checks."
      namespace   = "AWS/ApplicationELB"
      metric      = "UnHealthyHostCount"
      statistic   = "Maximum"
      extended    = null
      threshold   = 0
      comparison  = "GreaterThanThreshold"
      periods     = 3
      dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
    }
    target-latency-p95 = {
      description = "p95 response time is above the target."
      namespace   = "AWS/ApplicationELB"
      metric      = "TargetResponseTime"
      statistic   = null
      extended    = "p95"
      threshold   = var.latency_p95_seconds
      comparison  = "GreaterThanThreshold"
      periods     = 3
      dimensions  = { LoadBalancer = var.alb_arn_suffix, TargetGroup = var.target_group_arn_suffix }
    }
    ecs-memory = {
      description = "Service memory is close to the task limit (OOM kills next)."
      namespace   = "AWS/ECS"
      metric      = "MemoryUtilization"
      statistic   = "Average"
      extended    = null
      threshold   = 85
      comparison  = "GreaterThanThreshold"
      periods     = 3
      dimensions  = { ClusterName = var.ecs_cluster_name, ServiceName = var.ecs_service_name }
    }
    rds-cpu = {
      description = "Database CPU is saturated."
      namespace   = "AWS/RDS"
      metric      = "CPUUtilization"
      statistic   = "Average"
      extended    = null
      threshold   = 80
      comparison  = "GreaterThanThreshold"
      periods     = 3
      dimensions  = { DBInstanceIdentifier = var.db_instance_identifier }
    }
    rds-free-storage = {
      description = "Database free storage is below 2 GiB."
      namespace   = "AWS/RDS"
      metric      = "FreeStorageSpace"
      statistic   = "Minimum"
      extended    = null
      threshold   = 2147483648
      comparison  = "LessThanThreshold"
      periods     = 1
      dimensions  = { DBInstanceIdentifier = var.db_instance_identifier }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name          = "${var.name}-${each.key}"
  alarm_description   = each.value.description
  namespace           = each.value.namespace
  metric_name         = each.value.metric
  statistic           = each.value.statistic
  extended_statistic  = each.value.extended
  dimensions          = each.value.dimensions
  period              = 60
  evaluation_periods  = each.value.periods
  threshold           = each.value.threshold
  comparison_operator = each.value.comparison
  treat_missing_data  = "notBreaching"

  alarm_actions = local.actions
  ok_actions    = local.actions
}
