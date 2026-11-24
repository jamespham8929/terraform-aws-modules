# Plan and mock-apply tests. The mock provider stands in for AWS.

mock_provider "aws" {
  mock_resource "aws_lb" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test/abc" }
  }
  mock_resource "aws_lb_target_group" {
    defaults = { arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-app/abc" }
  }
}

variables {
  name                       = "test"
  vpc_id                     = "vpc-12345678"
  subnet_ids                 = ["subnet-aaaa1111", "subnet-bbbb2222"]
  enable_deletion_protection = false
  target_groups = {
    app = { port = 8080, target_type = "ip", health_check_path = "/health" }
  }
}

run "http_redirects_to_https_when_there_is_a_certificate" {
  command = apply

  variables {
    certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/abc"
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "redirect"
    error_message = "port 80 should redirect when HTTPS is available"
  }
  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "an HTTPS listener should exist"
  }
  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS should use the TLS 1.3 policy"
  }
}

# Before this, port 80 redirected to an HTTPS listener that did not exist, so
# an ALB without a certificate served nothing.
run "http_serves_the_target_without_a_certificate" {
  command = apply

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "forward"
    error_message = "without HTTPS, port 80 should forward to the target group"
  }
  assert {
    condition     = aws_lb_listener.http.default_action[0].target_group_arn == aws_lb_target_group.this["app"].arn
    error_message = "port 80 should forward to the default target group"
  }
  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "no HTTPS listener without a certificate"
  }
}

run "drops_invalid_headers" {
  command = plan

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields
    error_message = "invalid header fields should be dropped to block request smuggling"
  }
}

run "waf_is_attached_when_given" {
  command = plan

  variables {
    waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/test/abc"
  }

  assert {
    condition     = length(aws_wafv2_web_acl_association.this) == 1
    error_message = "a web ACL ARN should create an association"
  }
}

run "no_waf_by_default" {
  command = plan

  assert {
    condition     = length(aws_wafv2_web_acl_association.this) == 0
    error_message = "no association without a web ACL"
  }
}

run "needs_a_target_group" {
  command = plan

  variables {
    target_groups = {}
  }

  expect_failures = [var.target_groups]
}
