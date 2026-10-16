terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # bucket and region come from -backend-config (see README / CI workflow).
  # use_lockfile = S3-native state locking; no DynamoDB table needed.
  backend "s3" {
    key          = "web-app/dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = "dev"
      ManagedBy   = "terraform"
      Repository  = var.repository
    }
  }
}
