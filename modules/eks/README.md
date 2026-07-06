# eks

EKS cluster with managed node groups, IRSA OIDC provider, and control plane logging.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| cluster\_addons | Map of EKS add-ons to install (name -> { version }) | <pre>map(object({<br/>    version = string<br/>  }))</pre> | `{}` | no |
| cluster\_name | Name of the EKS cluster | `string` | n/a | yes |
| endpoint\_public\_access | Allow the Kubernetes API server endpoint to be accessible from the internet | `bool` | `true` | no |
| kubernetes\_version | Kubernetes version for the EKS cluster | `string` | `"1.30"` | no |
| node\_groups | Map of node group configurations | <pre>map(object({<br/>    instance_types = list(string)<br/>    desired_size   = number<br/>    min_size       = number<br/>    max_size       = number<br/>    disk_size      = number<br/>    labels         = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| private\_subnet\_ids | Subnet IDs for worker nodes and control plane ENIs | `list(string)` | n/a | yes |
| public\_access\_cidrs | CIDR blocks that can reach the public API endpoint | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| public\_subnet\_ids | Subnet IDs for public-facing load balancers | `list(string)` | `[]` | no |
| tags | Tags applied to every resource in this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| cluster\_arn | ARN of the EKS cluster |
| cluster\_certificate\_authority\_data | Base64-encoded certificate authority data for the cluster |
| cluster\_endpoint | Endpoint for the Kubernetes API server |
| cluster\_id | Name/ID of the EKS cluster |
| cluster\_version | Kubernetes version running on the cluster |
| node\_role\_arn | ARN of the IAM role attached to worker nodes |
| oidc\_provider\_arn | ARN of the IAM OIDC provider (used to create IRSA roles) |
| oidc\_provider\_url | URL of the IAM OIDC provider |
<!-- END_TF_DOCS -->
