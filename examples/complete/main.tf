provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "../../modules/vpc"

  name            = "example"
  cidr            = "10.0.0.0/16"
  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_flow_logs   = true

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

module "eks" {
  source = "../../modules/eks"

  cluster_name       = "example"
  kubernetes_version = "1.30"
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  endpoint_public_access = true
  public_access_cidrs    = ["10.0.0.0/8"]

  node_groups = {
    general = {
      instance_types = ["m6i.xlarge"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      disk_size      = 50
      labels         = { role = "general" }
    }
    memory-optimized = {
      instance_types = ["r6i.2xlarge"]
      desired_size   = 1
      min_size       = 0
      max_size       = 5
      disk_size      = 50
      labels         = { role = "memory" }
    }
  }

  cluster_addons = {
    coredns = { version = "v1.11.1-eksbuild.4" }
    kube-proxy = { version = "v1.30.0-eksbuild.3" }
    vpc-cni = { version = "v1.18.1-eksbuild.1" }
    aws-ebs-csi-driver = { version = "v1.31.0-eksbuild.1" }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

module "rds" {
  source = "../../modules/rds"

  identifier    = "example-postgres"
  engine        = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.medium"
  db_name       = "appdb"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks    = [module.vpc.vpc_cidr_block]
  multi_az               = true
  deletion_protection    = false
  skip_final_snapshot    = true

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

module "alb" {
  source = "../../modules/alb"

  name       = "example"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids

  enable_deletion_protection = false

  target_groups = {
    app = {
      port              = 8080
      target_type       = "ip"
      health_check_path = "/health"
    }
  }

  tags = {
    Environment = "example"
    ManagedBy   = "terraform"
  }
}

output "vpc_id"           { value = module.vpc.vpc_id }
output "eks_endpoint"     { value = module.eks.cluster_endpoint }
output "rds_endpoint"     { value = module.rds.db_instance_endpoint }
output "alb_dns_name"     { value = module.alb.alb_dns_name }
