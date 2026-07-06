# terraform-aws-modules

Production-ready Terraform modules for common AWS infrastructure patterns. Each module is self-contained with sensible defaults, explicit variable definitions, and tagged outputs.

## Modules

| Module | Description |
|--------|-------------|
| [vpc](./modules/vpc) | Multi-AZ VPC with public/private subnets, NAT gateways, and VPC flow logs |
| [eks](./modules/eks) | EKS cluster with managed node groups, IRSA OIDC provider, and control plane logging |
| [rds](./modules/rds) | RDS instance with Multi-AZ standby, automated backups, and KMS encryption |
| [alb](./modules/alb) | Application Load Balancer with HTTPS redirect, WAF association, and target group |

## Requirements

- Terraform >= 1.5
- AWS provider >= 5.0
- Go >= 1.21 (tests only)

## Usage

See [examples/complete](./examples/complete) for a full working example that wires all modules together.

```hcl
module "vpc" {
  source = "./modules/vpc"

  name            = "production"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = { Environment = "production" }
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = "production"
  kubernetes_version = "1.30"
  private_subnet_ids = module.vpc.private_subnet_ids

  node_groups = {
    general = {
      instance_types = ["m6i.xlarge"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      disk_size      = 50
    }
  }

  tags = { Environment = "production" }
}
```

## Testing

Tests use [Terratest](https://terratest.gruntwork.io/) and deploy real resources. Run against a real AWS account with appropriate permissions.

```bash
cd tests
go test -v -run TestVPCModule -timeout 30m
go test -v -run TestEKSModule -timeout 60m
```

The EKS test stands up a VPC first and tears it down last, so a single run
provisions and destroys the full cluster. Coverage for the RDS and ALB modules
is planned.

Set `AWS_PROFILE` or standard AWS environment variables before running. Tests clean up all resources on completion or failure.

## CI

On every pull request, GitHub Actions runs:

- `terraform fmt -check` across all modules
- `terraform validate` per module
- `tflint` with the AWS ruleset

See [.github/workflows/validate.yml](./.github/workflows/validate.yml).

## License

MIT
