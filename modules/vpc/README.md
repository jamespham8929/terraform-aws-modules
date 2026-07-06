# vpc

Multi-AZ VPC with public and private subnets, NAT gateways, and VPC flow logs.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| azs | Availability zones to deploy subnets into | `list(string)` | n/a | yes |
| cidr | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |
| enable\_flow\_logs | Publish VPC flow logs to CloudWatch Logs | `bool` | `true` | no |
| enable\_nat\_gateway | Provision NAT gateways so private subnets can reach the internet | `bool` | `true` | no |
| name | Name prefix applied to all resources | `string` | n/a | yes |
| private\_subnets | CIDR blocks for private subnets (one per AZ) | `list(string)` | `[]` | no |
| public\_subnets | CIDR blocks for public subnets (one per AZ) | `list(string)` | `[]` | no |
| single\_nat\_gateway | Share a single NAT gateway across all private subnets (reduces cost, removes HA) | `bool` | `false` | no |
| tags | Tags applied to every resource in this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| internet\_gateway\_id | ID of the internet gateway |
| nat\_gateway\_ids | IDs of the NAT gateways |
| private\_route\_table\_ids | IDs of the private route tables |
| private\_subnet\_ids | IDs of the private subnets |
| public\_subnet\_ids | IDs of the public subnets |
| vpc\_cidr\_block | CIDR block of the VPC |
| vpc\_id | ID of the VPC |
<!-- END_TF_DOCS -->
