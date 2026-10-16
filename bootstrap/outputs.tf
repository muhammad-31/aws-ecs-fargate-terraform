output "state_bucket" {
  description = "Terraform state bucket (GitHub variable TF_STATE_BUCKET)."
  value       = aws_s3_bucket.state.id
}

output "ecr_repository_url" {
  description = "ECR repository for the application image."
  value       = aws_ecr_repository.app.repository_url
}

output "plan_role_arn" {
  description = "Role for terraform plan (GitHub variable AWS_PLAN_ROLE_ARN)."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arns" {
  description = "Apply role per environment (GitHub variables AWS_APPLY_ROLE_ARN_<ENV>)."
  value       = { for env, role in aws_iam_role.apply : env => role.arn }
}

output "deploy_role_arn" {
  description = "Role for image push and ECS deploys (GitHub variable AWS_DEPLOY_ROLE_ARN)."
  value       = aws_iam_role.deploy.arn
}

output "github_variables" {
  description = "Copy these into Settings -> Secrets and variables -> Actions -> Variables."
  value = merge(
    {
      AWS_REGION          = var.aws_region
      TF_STATE_BUCKET     = aws_s3_bucket.state.id
      AWS_PLAN_ROLE_ARN   = aws_iam_role.plan.arn
      AWS_DEPLOY_ROLE_ARN = aws_iam_role.deploy.arn
      ECR_REPOSITORY      = aws_ecr_repository.app.name
    },
    { for env, role in aws_iam_role.apply : "AWS_APPLY_ROLE_ARN_${upper(env)}" => role.arn },
  )
}
