# Changelog

This project uses [semantic versioning](https://semver.org). Before 1.0, a minor
version can change defaults.

## 0.2.0 (2026-11-23)

### Changed defaults (check these before you upgrade)

- eks: `endpoint_public_access` is now `false`. Set it to `true` and narrow
  `public_access_cidrs` if you need the API from outside the VPC.
- eks: Kubernetes secrets are envelope encrypted. The module creates a KMS key
  with rotation on, unless you pass `secrets_kms_key_arn`. Adding encryption to
  an existing cluster is a one-way change.
- rds: with `manage_master_password = true`, RDS now creates the password,
  stores it in Secrets Manager, and rotates it. The `random_password` and the
  module's own secret are gone, so the password is no longer in Terraform
  state. `master_password_secret_arn` now points at the RDS-managed secret.
- rds: the security group has no egress rule. The database does not need to
  open connections of its own.
- alb: `target_groups` is now required and must hold at least one entry.
- vpc: with a NAT gateway per AZ, the module creates one per private subnet,
  not one per public subnet. A spare public subnet no longer costs an idle NAT.

### Fixed

- vpc: `enable_nat_gateway = false` with more than one private subnet failed to
  plan. Every private subnet now uses the one private route table.
- vpc: a per-AZ NAT layout with fewer public than private subnets now fails
  with a clear message instead of an index error.
- alb: without a certificate, port 80 redirected to an HTTPS listener that did
  not exist. It now forwards to the default target group.
- alb: the README promised a WAF association that the module did not have. Set
  `waf_web_acl_arn` to attach a WAFv2 web ACL.
- examples: the EKS add-on versions were built for Kubernetes 1.30, but the
  cluster runs 1.32. Unset versions now install the default build for the
  cluster.
- Every module declares `required_version`, which tflint requires.

### Added

- `terraform test` plan tests for every module, against mock providers.
- checkov in CI, with each exception documented on its resource.
- vpc: the default security group is managed and allows nothing.
- vpc: `flow_log_retention_days` and `flow_log_kms_key_id`.
- vpc: the flow log role can only write to its own log group.
- rds: Performance Insights uses `kms_key_id` when it is set.

## 0.1.0

First release: vpc, eks, rds, and alb modules, a complete example, terratests,
and terraform-docs in CI.
