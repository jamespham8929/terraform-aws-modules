variable "name" {
  description = "Name prefix applied to all resources"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to deploy subnets into"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Provision NAT gateways so private subnets can reach the internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Share a single NAT gateway across all private subnets (reduces cost, removes HA)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Publish VPC flow logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}

variable "flow_log_retention_days" {
  description = "Days to keep VPC flow logs in CloudWatch Logs"
  type        = number
  default     = 30
}

variable "flow_log_kms_key_id" {
  description = "KMS key ARN to encrypt the flow log group (null for the default CloudWatch encryption)"
  type        = string
  default     = null
}
