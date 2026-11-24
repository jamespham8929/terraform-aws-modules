# Plan-only tests against a mock AWS provider. No account needed.

mock_provider "aws" {}

variables {
  identifier          = "test-db"
  engine              = "postgres"
  engine_version      = "16.4"
  instance_class      = "db.t4g.medium"
  db_name             = "app"
  vpc_id              = "vpc-12345678"
  subnet_ids          = ["subnet-aaaa1111", "subnet-bbbb2222"]
  allowed_cidr_blocks = ["10.0.0.0/16"]
}

run "storage_is_encrypted_and_private" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted
    error_message = "storage must be encrypted"
  }
  assert {
    condition     = !aws_db_instance.this.publicly_accessible
    error_message = "the instance must not get a public IP"
  }
  assert {
    condition     = aws_db_instance.this.storage_type == "gp3"
    error_message = "gp3 is cheaper than gp2 at the same baseline"
  }
}

run "rds_manages_the_master_password_by_default" {
  command = plan

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "RDS should create and rotate the master password"
  }
  assert {
    condition     = aws_db_instance.this.password == null
    error_message = "no password should pass through Terraform, so none lands in state"
  }
}

run "a_supplied_password_needs_to_be_long_enough" {
  command = plan

  variables {
    manage_master_password = false
    password               = "short"
  }

  expect_failures = [aws_db_instance.this]
}

run "a_supplied_password_is_used_as_is" {
  command = plan

  variables {
    manage_master_password = false
    password               = "a-long-enough-password"
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == null
    error_message = "a supplied password turns off RDS-managed credentials"
  }
}

run "only_the_allowed_cidrs_reach_the_port" {
  command = plan

  assert {
    condition = alltrue([
      for rule in aws_security_group.this.ingress :
      rule.from_port == 5432 && rule.cidr_blocks == tolist(["10.0.0.0/16"])
    ])
    error_message = "ingress should be limited to the database port and the allowed CIDRs"
  }
}

run "the_database_opens_no_outbound_connections" {
  # egress is computed, so apply against the mock to see the final rule set.
  command = apply

  assert {
    condition     = length(aws_security_group.this.egress) == 0
    error_message = "the RDS security group should have no egress rules"
  }
}

run "a_final_snapshot_is_kept_unless_skipped" {
  command = plan

  variables {
    skip_final_snapshot = false
  }

  assert {
    condition     = aws_db_instance.this.final_snapshot_identifier == "test-db-final"
    error_message = "deleting the instance should leave a final snapshot"
  }
}
