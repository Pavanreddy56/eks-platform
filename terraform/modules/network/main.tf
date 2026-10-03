# VPC with public, private and isolated database subnets across two AZs.
# Subnets are tagged so the AWS Load Balancer Controller can discover them.

module "vpc" {
  #checkov:skip=CKV_TF_1:Registry module pinned to an exact version; commit-hash sources would bypass the registry
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # exact pin for reproducible plans; Dependabot proposes upgrades

  name = var.name
  cidr = var.cidr
  azs  = var.azs

  private_subnets  = [for i, _ in var.azs : cidrsubnet(var.cidr, 4, i)]
  public_subnets   = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, i + 48)]
  database_subnets = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, i + 52)]

  create_database_subnet_group = true

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway # one NAT in dev to save cost
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Lock down the default security group (no rules).
  manage_default_security_group = true

  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role             = var.enable_flow_log
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 7

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}
