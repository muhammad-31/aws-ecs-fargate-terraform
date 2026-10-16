# Wires every module together against a mocked AWS provider. Catches broken
# references, dependency cycles and variable validation without an AWS account.

mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

  mock_data "aws_elb_service_account" {
    defaults = {
      arn = "arn:aws:iam::054676820928:root"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-central-1:111122223333:key/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-central-1:111122223333:log-group:mock"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/mock"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn        = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/mock/0123456789abcdef"
      arn_suffix = "app/mock/0123456789abcdef"
      dns_name   = "mock-123456.eu-central-1.elb.amazonaws.com"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn        = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:targetgroup/mock/0123456789abcdef"
      arn_suffix = "targetgroup/mock/0123456789abcdef"
    }
  }

  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:eu-central-1:111122223333:regional/webacl/mock/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:eu-central-1:111122223333:mock-alarms"
    }
  }

  mock_resource "aws_ecs_task_definition" {
    defaults = {
      arn = "arn:aws:ecs:eu-central-1:111122223333:task-definition/mock:1"
    }
  }

  mock_resource "aws_db_instance" {
    defaults = {
      address = "mock.abcdefghijkl.eu-central-1.rds.amazonaws.com"
      port    = 5432
      master_user_secret = [{
        secret_arn    = "arn:aws:secretsmanager:eu-central-1:111122223333:secret:rds!db-mock-AbCdEf"
        kms_key_id    = "arn:aws:kms:eu-central-1:111122223333:alias/aws/secretsmanager"
        secret_status = "active"
      }]
    }
  }
}

variables {
  project         = "shop"
  environment     = "dev"
  vpc_cidr        = "10.10.0.0/16"
  container_image = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/shop:bootstrap"
}

run "dev_stack_without_certificate_serves_http" {
  command = apply

  variables {
    deletion_protection = false
    use_fargate_spot    = true
  }

  assert {
    condition     = startswith(output.app_url, "http://")
    error_message = "Without a certificate the app URL should be plain HTTP."
  }

  assert {
    condition     = output.ecs_cluster_name == "shop-dev" && output.ecs_task_family == "shop-dev"
    error_message = "Resources should be named <project>-<environment>."
  }

  assert {
    condition     = output.db_secret_arn == "arn:aws:secretsmanager:eu-central-1:111122223333:secret:rds!db-mock-AbCdEf"
    error_message = "The service should use the RDS-managed master secret."
  }
}

run "prod_stack_with_certificate_serves_https" {
  command = apply

  variables {
    environment                = "prod"
    vpc_cidr                   = "10.30.0.0/16"
    az_count                   = 3
    single_nat_gateway         = false
    enable_interface_endpoints = true
    certificate_arn            = "arn:aws:acm:eu-central-1:111122223333:certificate/11111111-2222-3333-4444-555555555555"
    db_multi_az                = true
    min_tasks                  = 2
  }

  assert {
    condition     = startswith(output.app_url, "https://")
    error_message = "With a certificate the app URL should be HTTPS."
  }

  assert {
    condition     = length(output.nat_public_ips) == 3
    error_message = "Prod should have one NAT gateway (and egress IP) per AZ."
  }
}

run "rejects_invalid_project_name" {
  command = plan

  variables {
    project = "Shop_App"
  }

  expect_failures = [var.project]
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
