terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  https_enabled = var.certificate_arn != ""

  # Map keys iterate in sorted order, so the default target is stable.
  default_target_group_arn = values(aws_lb_target_group.this)[0].arn
}

resource "aws_security_group" "alb" {
  #checkov:skip=CKV_AWS_260:Port 80 is open so plain HTTP can be redirected to HTTPS. It forwards only when no certificate is set.
  #checkov:skip=CKV_AWS_382:The ALB reaches targets on ports the caller picks per target group, so egress is not narrowed here.
  name        = "${var.name}-alb"
  description = "Security group for ${var.name} ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP, redirected to HTTPS when a certificate is set"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Traffic to targets and health checks"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb" })
}

resource "aws_lb" "this" {
  #checkov:skip=CKV2_AWS_76:The web ACL is the caller's, passed in as waf_web_acl_arn, so its managed rules are set there.
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = true
  drop_invalid_header_fields       = true

  access_logs {
    bucket  = var.access_logs_bucket
    prefix  = var.name
    enabled = var.access_logs_bucket != ""
  }

  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  #checkov:skip=CKV_AWS_378:TLS ends at the ALB. Targets get HTTP inside the VPC, which is the common pattern and keeps certificates off the pods.
  for_each = var.target_groups

  name        = "${var.name}-${each.key}"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-299"
  }

  tags = var.tags
}

# With a certificate, port 80 only redirects to HTTPS. Without one, there is no
# HTTPS listener to redirect to, so port 80 serves the default target instead.
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:This listener redirects to HTTPS. It forwards plain HTTP only when no certificate is set.
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.https_enabled ? "redirect" : "forward"
    target_group_arn = local.https_enabled ? null : local.default_target_group_arn

    dynamic "redirect" {
      for_each = local.https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.https_enabled ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = local.default_target_group_arn
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.waf_web_acl_arn != "" ? 1 : 0

  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}
