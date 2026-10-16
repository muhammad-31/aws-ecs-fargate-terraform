# Unit tests for the network module. They run against a mocked AWS provider,
# so they need no credentials and create nothing: `terraform test`.

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

  # Mocked policy documents must still be valid JSON for the provider's
  # plan-time validation.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # Generated values are random strings; give ARN attributes ARN-shaped values.
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:eu-central-1:111122223333:log-group:/vpc/unit/flow-logs"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111122223333:role/unit-vpc-flow-logs"
    }
  }
}

variables {
  name        = "unit"
  cidr_block  = "10.20.0.0/16"
  kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/11111111-2222-3333-4444-555555555555"
}

run "dev_layout_uses_one_nat_and_no_paid_endpoints" {
  command = apply

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway should create exactly one NAT gateway."
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface) == 0
    error_message = "Interface endpoints must be opt-in."
  }

  assert {
    condition     = alltrue([for rt in aws_route_table.app : one(rt.route).nat_gateway_id == aws_nat_gateway.this[0].id])
    error_message = "Every app route table should use the shared NAT gateway."
  }

  assert {
    condition     = length(aws_route_table.data.route) == 0
    error_message = "Data subnets must not have a route to the internet."
  }
}

run "subnet_cidrs_follow_the_documented_layout" {
  command = plan

  variables {
    az_count = 3
  }

  assert {
    condition     = aws_subnet.public[*].cidr_block == ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"]
    error_message = "Unexpected public subnet CIDRs."
  }

  assert {
    condition     = aws_subnet.app[*].cidr_block == ["10.20.16.0/20", "10.20.32.0/20", "10.20.48.0/20"]
    error_message = "Unexpected app subnet CIDRs."
  }

  assert {
    condition     = aws_subnet.data[*].cidr_block == ["10.20.100.0/24", "10.20.101.0/24", "10.20.102.0/24"]
    error_message = "Unexpected data subnet CIDRs."
  }

  assert {
    condition     = length(distinct(aws_subnet.app[*].availability_zone)) == 3
    error_message = "App subnets should be spread over three AZs."
  }
}

run "prod_layout_has_nat_per_az_and_endpoints" {
  command = apply

  variables {
    az_count                   = 3
    single_nat_gateway         = false
    enable_interface_endpoints = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Expected one NAT gateway per AZ."
  }

  assert {
    condition     = toset(keys(aws_vpc_endpoint.interface)) == toset(["ecr.api", "ecr.dkr", "logs", "secretsmanager"])
    error_message = "Expected ECR, Logs and Secrets Manager interface endpoints."
  }

  assert {
    condition     = alltrue([for i, rt in aws_route_table.app : one(rt.route).nat_gateway_id == aws_nat_gateway.this[i].id])
    error_message = "Each AZ should route through its own NAT gateway."
  }
}

run "rejects_cidr_that_is_not_a_16" {
  command = plan

  variables {
    cidr_block = "10.20.0.0/20"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_single_az" {
  command = plan

  variables {
    az_count = 1
  }

  expect_failures = [var.az_count]
}
