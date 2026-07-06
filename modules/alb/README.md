# alb

Application Load Balancer with HTTPS redirect, WAF association, and target group.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| access\_logs\_bucket | S3 bucket name to store ALB access logs (empty to disable) | `string` | `""` | no |
| certificate\_arn | ACM certificate ARN to attach to the HTTPS listener | `string` | `""` | no |
| enable\_deletion\_protection | Prevent accidental deletion of the ALB | `bool` | `true` | no |
| internal | Set true to create an internal (private) load balancer | `bool` | `false` | no |
| name | Name of the load balancer and associated resources | `string` | n/a | yes |
| subnet\_ids | Public subnet IDs to place the ALB in | `list(string)` | n/a | yes |
| tags | Tags applied to every resource in this module | `map(string)` | `{}` | no |
| target\_groups | Map of target group configurations | <pre>map(object({<br/>    port              = number<br/>    target_type       = string<br/>    health_check_path = string<br/>  }))</pre> | `{}` | no |
| vpc\_id | VPC to create the ALB in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| alb\_arn | ARN of the Application Load Balancer |
| alb\_dns\_name | DNS name of the ALB |
| alb\_zone\_id | Hosted zone ID for Route 53 alias records |
| http\_listener\_arn | ARN of the HTTP (port 80) listener |
| https\_listener\_arn | ARN of the HTTPS (port 443) listener |
| security\_group\_id | ID of the ALB security group |
| target\_group\_arns | Map of target group name to ARN |
<!-- END_TF_DOCS -->
