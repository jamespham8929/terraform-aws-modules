terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_db_subnet_group" "this" {
  name       = var.identifier
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = var.identifier })
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-rds"
  description = "Security group for ${var.identifier} RDS instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "Database clients"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # No egress block. Terraform then removes AWS's default allow-all egress
  # rule. The database answers its clients through connection tracking and
  # does not need to open connections of its own.

  tags = merge(var.tags, { Name = "${var.identifier}-rds" })
}

resource "aws_db_instance" "this" {
  #checkov:skip=CKV_AWS_118:Enhanced monitoring needs its own IAM role and costs extra. Performance Insights is on and covers most of the same questions.
  #checkov:skip=CKV2_AWS_30:Query logging is engine specific and belongs in a parameter group the caller owns.
  #checkov:skip=CKV_AWS_354:Performance Insights uses kms_key_id when it is set, and the AWS managed key otherwise.
  identifier        = var.identifier
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  db_name  = var.db_name
  username = var.username

  # RDS creates the master password, keeps it in Secrets Manager, and rotates
  # it. Terraform never sees it, so it never lands in state.
  manage_master_user_password   = var.manage_master_password ? true : null
  master_user_secret_kms_key_id = var.manage_master_password ? var.kms_key_id : null
  password                      = var.manage_master_password ? null : var.password

  port                   = var.port
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  multi_az            = var.multi_az
  publicly_accessible = false
  deletion_protection = var.deletion_protection

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = var.kms_key_id

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${var.identifier}-final"

  tags = var.tags

  lifecycle {
    precondition {
      condition     = var.manage_master_password || length(var.password) >= 8
      error_message = "Set password (8 characters or more) when manage_master_password is false."
    }
  }
}
