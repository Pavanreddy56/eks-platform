# EKS control plane plus one managed node group (Spot by default in dev).

module "eks" {
  #checkov:skip=CKV_TF_1:Registry module pinned to an exact version; commit-hash sources would bypass the registry
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0" # exact pin for reproducible plans; Dependabot proposes upgrades

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Auto-upgrade at end of standard support instead of paying the
  # extended-support premium (FinOps guardrail).
  upgrade_policy = {
    support_type = "STANDARD"
  }

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
  endpoint_private_access      = true

  # Grants the identity running Terraform cluster-admin via an access entry.
  enable_cluster_creator_admin_permissions = true

  enabled_log_types                      = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = 7

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    eks-pod-identity-agent = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      labels = {
        workload = "general"
      }
    }
  }

  tags = var.tags
}
