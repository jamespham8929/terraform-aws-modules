# Outputs the wired-together stack returns. These are the values you would feed
# into a kubeconfig, an application config, or a DNS record after apply.

output "vpc_id" {
  description = "ID of the VPC hosting the stack"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by the EKS nodes and the RDS subnet group"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB"
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "Kubernetes API server endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for creating IRSA roles"
  value       = module.eks.oidc_provider_arn
}

output "rds_endpoint" {
  description = "RDS connection endpoint (host:port)"
  value       = module.rds.db_instance_endpoint
}

output "rds_master_password_secret_arn" {
  description = "Secrets Manager ARN holding the generated RDS master password"
  value       = module.rds.master_password_secret_arn
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}
