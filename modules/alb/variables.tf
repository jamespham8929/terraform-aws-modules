variable "name" {
  description = "Name of the load balancer and associated resources"
  type        = string
}

variable "vpc_id" {
  description = "VPC to create the ALB in"
  type        = string
}

variable "subnet_ids" {
  description = "Public subnet IDs to place the ALB in"
  type        = list(string)
}

variable "internal" {
  description = "Set true to create an internal (private) load balancer"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ACM certificate ARN to attach to the HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Prevent accidental deletion of the ALB"
  type        = bool
  default     = true
}

variable "access_logs_bucket" {
  description = "S3 bucket name to store ALB access logs (empty to disable)"
  type        = string
  default     = ""
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port              = number
    target_type       = string
    health_check_path = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}
