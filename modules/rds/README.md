# rds

RDS instance with Multi-AZ standby, automated backups, and KMS encryption.

<!-- BEGIN_TF_DOCS -->
## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allocated\_storage | Storage size in GB | `number` | `20` | no |
| allowed\_cidr\_blocks | CIDR blocks allowed to reach the database port | `list(string)` | `[]` | no |
| backup\_retention\_period | Days to retain automated backups | `number` | `7` | no |
| backup\_window | Daily time range for automated backups (UTC) | `string` | `"03:00-04:00"` | no |
| db\_name | Name of the initial database | `string` | n/a | yes |
| deletion\_protection | Prevent accidental deletion of the instance | `bool` | `true` | no |
| enabled\_cloudwatch\_logs\_exports | Log types to export to CloudWatch | `list(string)` | <pre>[<br/>  "postgresql"<br/>]</pre> | no |
| engine | Database engine (postgres, mysql, etc.) | `string` | `"postgres"` | no |
| engine\_version | Engine version | `string` | `"15.4"` | no |
| identifier | Unique identifier for the RDS instance and associated resources | `string` | n/a | yes |
| instance\_class | RDS instance class | `string` | `"db.t3.medium"` | no |
| kms\_key\_id | ARN of the KMS key used to encrypt storage (defaults to AWS-managed key) | `string` | `null` | no |
| maintenance\_window | Weekly time range for maintenance (UTC) | `string` | `"Mon:04:00-Mon:05:00"` | no |
| manage\_master\_password | Generate and store the master password in Secrets Manager | `bool` | `true` | no |
| multi\_az | Deploy a Multi-AZ standby for high availability | `bool` | `true` | no |
| password | Master password (ignored when manage\_master\_password = true) | `string` | `""` | no |
| port | Port the database listens on | `number` | `5432` | no |
| skip\_final\_snapshot | Skip final snapshot on deletion (set true for dev environments) | `bool` | `false` | no |
| subnet\_ids | Private subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| tags | Tags applied to every resource in this module | `map(string)` | `{}` | no |
| username | Master username | `string` | `"admin"` | no |
| vpc\_id | VPC to place the RDS instance in | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| db\_instance\_address | Hostname of the RDS instance |
| db\_instance\_arn | ARN of the RDS instance |
| db\_instance\_endpoint | Connection endpoint (host:port) |
| db\_instance\_id | RDS instance identifier |
| db\_instance\_port | Port the instance listens on |
| db\_security\_group\_id | ID of the security group attached to the RDS instance |
| master\_password\_secret\_arn | ARN of the Secrets Manager secret holding the master password |
<!-- END_TF_DOCS -->
