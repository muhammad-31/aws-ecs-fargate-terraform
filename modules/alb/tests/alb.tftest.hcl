mock_provider "aws" {
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

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::unit-alb-logs"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:loadbalancer/app/unit/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:targetgroup/unit-app/0123456789abcdef"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-central-1:111122223333:log-group:aws-waf-logs-unit"
    }
  }

  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      arn = "arn:aws:wafv2:eu-central-1:111122223333:regional/webacl/unit/11111111-2222-3333-4444-555555555555"
    }
  }
}

variables {
  name              = "unit"
  vpc_id            = "vpc-0123456789abcdef0"
  vpc_cidr_block    = "10.20.0.0/16"
  public_subnet_ids = ["subnet-0aaaaaaaaaaaaaaa1", "subnet-0aaaaaaaaaaaaaaa2"]
  target_port       = 8000
  kms_key_arn       = "arn:aws:kms:eu-central-1:111122223333:key/11111111-2222-3333-4444-555555555555"
}

run "without_certificate_only_http_forward_exists" {
  command = apply

  assert {
    condition     = length(aws_lb_listener.http_forward) == 1 && length(aws_lb_listener.https) == 0 && length(aws_lb_listener.http_redirect) == 0
    error_message = "Without a certificate there should be a single HTTP forward listener."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.https) == 0
    error_message = "Port 443 should not be opened when there is no HTTPS listener."
  }
}

run "with_certificate_http_redirects_to_https" {
  command = apply

  variables {
    certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/11111111-2222-3333-4444-555555555555"
  }

  assert {
    condition     = length(aws_lb_listener.http_forward) == 0 && length(aws_lb_listener.https) == 1
    error_message = "With a certificate, traffic should be served over HTTPS only."
  }

  assert {
    condition     = one(aws_lb_listener.http_redirect[0].default_action).redirect[0].status_code == "HTTP_301"
    error_message = "HTTP should permanently redirect to HTTPS."
  }

  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS listener should use the TLS 1.3/1.2 policy."
  }
}

run "waf_can_be_disabled" {
  command = plan

  variables {
    enable_waf = false
  }

  assert {
    condition     = length(aws_wafv2_web_acl.this) == 0 && length(aws_wafv2_web_acl_association.this) == 0 && length(aws_cloudwatch_log_group.waf) == 0
    error_message = "enable_waf = false should not create WAF resources."
  }
}

run "rejects_names_too_long_for_alb" {
  command = plan

  variables {
    name = "this-name-is-far-too-long-for-an-alb"
  }

  expect_failures = [var.name]
}
