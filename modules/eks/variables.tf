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
  description = "Allow the Kubernetes API server endpoint to be accessible from the internet"
  type        = bool
  default     = true
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
  description = "Map of EKS add-ons to install (name -> { version })"
  type = map(object({
    version = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to every resource in this module"
  type        = map(string)
  default     = {}
}
