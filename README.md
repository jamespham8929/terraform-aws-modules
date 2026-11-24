# terraform-aws-modules

Production-ready Terraform modules for common AWS infrastructure patterns. Each module is self-contained with sensible defaults, explicit variable definitions, and tagged outputs.

## Modules

| Module | Description |
|--------|-------------|
| [vpc](./modules/vpc) | Multi-AZ VPC with public/private subnets, NAT gateways, VPC flow logs, and a default security group that allows nothing |
| [eks](./modules/eks) | EKS cluster with managed node groups, IRSA OIDC provider, control plane logging, KMS encryption of secrets, and a private API endpoint by default |
| [rds](./modules/rds) | RDS instance with Multi-AZ standby, automated backups, KMS encryption, and a master password RDS creates and rotates |
| [alb](./modules/alb) | Application Load Balancer with HTTPS redirect, optional WAF association, and target groups |

## Requirements

- Terraform >= 1.5 (1.7 or newer to run `terraform test`)
- AWS provider >= 5.0
- Go >= 1.21 (terratests only)

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

There are two layers.

Plan tests run with `terraform test` and need no AWS account. Each module has a
`tests/plan.tftest.hcl` that runs against a mock AWS provider. They check the
choices a module makes: how many NAT gateways a layout gets, that storage is
encrypted, that the RDS password never passes through Terraform, that port 80
forwards when there is no certificate. They run in seconds.

```bash
cd modules/vpc
terraform init -backend=false
terraform test
```

These tests found two bugs that `terraform validate` could not. A VPC with
`enable_nat_gateway = false` and more than one private subnet failed to plan.
And an ALB with no certificate redirected port 80 to an HTTPS listener that did
not exist.

Terratests deploy real resources. Run them against a real AWS account with appropriate permissions.

```bash
cd tests
go test -v -run TestVPCModule -timeout 30m
go test -v -run TestEKSModule -timeout 60m
go test -v -run TestRDSModule -timeout 45m
go test -v -run TestALBModule -timeout 30m
```

The EKS, RDS, and ALB tests each stand up a VPC first and tear it down last, so a
single run provisions and destroys the full set of resources it needs.

Set `AWS_PROFILE` or standard AWS environment variables before running. Tests clean up all resources on completion or failure.

## CI

On every pull request, GitHub Actions runs:

- `terraform fmt -check` across all modules
- `terraform validate` per module, on Terraform 1.5
- `terraform test` per module, against mock providers
- `checkov` with the AWS policy set. A finding fails the build. A deliberate
  exception is a `checkov:skip` comment on the resource, with its reason
- `tflint` with the AWS ruleset
- `terraform-docs` to confirm each module's input and output tables are current

Each module's `README.md` inputs and outputs tables are generated with
[terraform-docs](https://terraform-docs.io). Regenerate them after changing a
module's variables or outputs:

```bash
for module in modules/*/; do
  terraform-docs --config .terraform-docs.yml "$module"
done
```

The CI docs job fails if the committed tables drift from the module source.

See [.github/workflows/validate.yml](./.github/workflows/validate.yml).

## Changes

See [CHANGELOG.md](./CHANGELOG.md). Version 0.2.0 changes some defaults, so read
it before you upgrade.

## License

MIT
