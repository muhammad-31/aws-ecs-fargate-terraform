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

output "apply_role_arn" {
  description = "Role for terraform apply (GitHub variable AWS_APPLY_ROLE_ARN)."
  value       = aws_iam_role.apply.arn
}

output "deploy_role_arn" {
  description = "Role for image push and ECS deploys (GitHub variable AWS_DEPLOY_ROLE_ARN)."
  value       = aws_iam_role.deploy.arn
}

output "github_variables" {
  description = "Copy these into Settings -> Secrets and variables -> Actions -> Variables."
  value = {
    AWS_REGION          = var.aws_region
    TF_STATE_BUCKET     = aws_s3_bucket.state.id
    AWS_PLAN_ROLE_ARN   = aws_iam_role.plan.arn
    AWS_APPLY_ROLE_ARN  = aws_iam_role.apply.arn
    AWS_DEPLOY_ROLE_ARN = aws_iam_role.deploy.arn
    ECR_REPOSITORY      = aws_ecr_repository.app.name
  }
}
