# Plan-only tests. The mock provider stands in for AWS, so these run in CI
# with no account and no cost. The terratests in /tests cover real applies.

mock_provider "aws" {
  # The provider validates ARN arguments, and mock values are random strings.
  # Give the resources whose ARNs feed other resources a well-formed one.
  mock_resource "aws_iam_role" {
    defaults = { arn = "arn:aws:iam::123456789012:role/mock" }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = { arn = "arn:aws:logs:us-east-1:123456789012:log-group:mock" }
  }
}

variables {
  name            = "test"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  tags            = { Environment = "test" }
}

run "one_nat_gateway_per_az_by_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "expected one NAT gateway per public subnet"
  }
  assert {
    condition     = length(aws_route_table.private) == 3
    error_message = "expected one private route table per private subnet"
  }
}

run "single_nat_gateway_shares_one_route_table" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_eip.nat) == 1
    error_message = "single_nat_gateway should create exactly one NAT gateway and EIP"
  }
  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "single_nat_gateway should share one private route table"
  }
}

# This case failed to plan before: one private route table, but each subnet
# association looked up its own index. Apply against the mock so the route
# table IDs are known and the test can check where each subnet points.
run "no_nat_gateway_shares_one_private_route_table" {
  command = apply

  variables {
    enable_nat_gateway = false
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_route_table.private) == 1
    error_message = "no NAT gateway and one private route table expected"
  }
  assert {
    condition     = alltrue([for a in aws_route_table_association.private : a.route_table_id == aws_route_table.private[0].id])
    error_message = "every private subnet should use the one private route table"
  }
  assert {
    condition     = length(aws_route_table.private[0].route) == 0
    error_message = "without NAT, private subnets get no default route"
  }
}

run "a_spare_public_subnet_does_not_buy_an_idle_nat_gateway" {
  command = plan

  variables {
    public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 2
    error_message = "NAT gateways should follow the private subnets that use them"
  }
}

run "subnets_spread_across_azs_and_carry_the_elb_role_tags" {
  command = plan

  assert {
    condition     = alltrue([for i, s in aws_subnet.private : s.availability_zone == var.azs[i]])
    error_message = "private subnets should land one per AZ"
  }
  assert {
    condition     = alltrue([for s in aws_subnet.public : s.tags["kubernetes.io/role/elb"] == "1"])
    error_message = "public subnets need the elb role tag for the AWS load balancer controller"
  }
  assert {
    condition     = alltrue([for s in aws_subnet.private : s.tags["kubernetes.io/role/internal-elb"] == "1"])
    error_message = "private subnets need the internal-elb role tag"
  }
}

run "flow_logs_capture_all_traffic" {
  command = plan

  assert {
    condition     = aws_flow_log.this[0].traffic_type == "ALL"
    error_message = "flow logs should capture accepted and rejected traffic"
  }
  assert {
    condition     = aws_cloudwatch_log_group.flow_log[0].retention_in_days > 0
    error_message = "flow log retention must be bounded"
  }
}

run "the_default_security_group_has_no_rules" {
  command = plan

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "the default security group should allow nothing"
  }
}

run "flow_logs_can_be_turned_off" {
  command = plan

  variables {
    enable_flow_logs = false
  }

  assert {
    condition     = length(aws_flow_log.this) == 0 && length(aws_iam_role.flow_log) == 0
    error_message = "disabling flow logs should drop the log, its group, and its role"
  }
}

run "per_az_nat_needs_a_public_subnet_for_every_private_one" {
  command = plan

  variables {
    public_subnets = ["10.0.101.0/24"]
  }

  expect_failures = [aws_nat_gateway.this]
}
