output "sns_topic_arn" {
  description = "SNS topic that receives every alarm and recovery notification."
  value       = aws_sns_topic.alarms.arn
}

output "alarm_names" {
  description = "Names of the CloudWatch alarms created."
  value       = [for a in aws_cloudwatch_metric_alarm.this : a.alarm_name]
}
