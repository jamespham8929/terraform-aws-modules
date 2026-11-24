# Plan-only tests against mock AWS and TLS providers.

mock_provider "aws" {}
mock_provider "tls" {}

variables {
  cluster_name       = "test"
  kubernetes_version = "1.33"
  private_subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]
  node_groups = {
    general = {
      instance_types = ["m6i.large"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      disk_size      = 50
    }
  }
}

run "control_plane_logs_everything" {
  command = plan

  assert {
    condition     = length(aws_eks_cluster.this.enabled_cluster_log_types) == 5
    error_message = "all five control plane log types should be on"
  }
  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access
    error_message = "nodes should reach the API server privately"
  }
}

run "nodes_live_in_private_subnets" {
  command = plan

  assert {
    condition     = aws_eks_node_group.this["general"].subnet_ids == toset(var.private_subnet_ids)
    error_message = "node groups belong in the private subnets"
  }
  assert {
    condition     = aws_eks_node_group.this["general"].scaling_config[0].max_size == 4
    error_message = "scaling config should pass through"
  }
}

run "addons_without_a_version_use_the_cluster_default" {
  command = plan

  variables {
    cluster_addons = {
      coredns = {}
      vpc-cni = { version = "v1.20.0-eksbuild.1" }
    }
  }

  assert {
    condition     = aws_eks_addon.this["vpc-cni"].addon_version == "v1.20.0-eksbuild.1"
    error_message = "a pinned add-on version should pass through"
  }
  assert {
    condition     = length(aws_eks_addon.this) == 2
    error_message = "both add-ons should be planned"
  }
}

run "the_api_endpoint_is_private_by_default" {
  command = plan

  assert {
    condition     = !aws_eks_cluster.this.vpc_config[0].endpoint_public_access
    error_message = "the public endpoint should be off unless asked for"
  }
}

run "secrets_get_a_rotating_kms_key_by_default" {
  command = plan

  assert {
    condition     = length(aws_kms_key.secrets) == 1 && aws_kms_key.secrets[0].enable_key_rotation
    error_message = "the module should create a rotating key when none is given"
  }
  assert {
    condition     = aws_eks_cluster.this.encryption_config[0].resources == toset(["secrets"])
    error_message = "Kubernetes secrets should be envelope encrypted"
  }
}

run "a_supplied_key_is_used_instead" {
  command = plan

  variables {
    secrets_kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/abc"
  }

  assert {
    condition     = length(aws_kms_key.secrets) == 0
    error_message = "no key should be created when one is supplied"
  }
  assert {
    condition     = aws_eks_cluster.this.encryption_config[0].provider[0].key_arn == "arn:aws:kms:us-east-1:123456789012:key/abc"
    error_message = "the supplied key should encrypt secrets"
  }
}
