variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "private_subnet_ids" {
  description = "Subnet IDs for worker nodes and control plane ENIs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Subnet IDs for public-facing load balancers"
  type        = list(string)
  default     = []
}

variable "endpoint_public_access" {
  description = "Allow the Kubernetes API server endpoint to be accessible from the internet. Off by default. If you turn it on, also narrow public_access_cidrs."
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDR blocks that can reach the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Map of node group configurations"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    disk_size      = number
    labels         = optional(map(string), {})
  }))
  default = {}
}

variable "cluster_addons" {
  description = "Map of EKS add-ons to install (name -> { version }). Leave version unset to get the default for the cluster's Kubernetes version."
  type = map(object({
    version = optional(string)
  }))
  default = {}
}

variable "secrets_kms_key_arn" {
  description = "KMS key ARN for envelope encryption of Kubernetes secrets. Null creates a key with rotation on."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}
