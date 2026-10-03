data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:Only the first two zones are used (slice below), so new AZs do not change the result
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project}-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ---------------------------------------------------------------- network --
module "network" {
  source = "../../modules/network"

  name               = local.name
  cidr               = var.vpc_cidr
  azs                = local.azs
  single_nat_gateway = var.single_nat_gateway
}

# -------------------------------------------------------------------- eks --
module "eks" {
  source = "../../modules/eks"

  cluster_name                 = local.name
  kubernetes_version           = var.kubernetes_version
  vpc_id                       = module.network.vpc_id
  private_subnet_ids           = module.network.private_subnet_ids
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  node_instance_types = var.node_instance_types
  node_capacity_type  = var.node_capacity_type
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
}

# -------------------------------------------------------------------- rds --
module "rds" {
  source = "../../modules/rds"

  name                       = local.name
  vpc_id                     = module.network.vpc_id
  db_subnet_group_name       = module.network.database_subnet_group_name
  allowed_security_group_ids = [module.eks.node_security_group_id]
  instance_class             = var.db_instance_class
  secret_name                = "${local.name}/db-credentials"
}

# -------------------------------------------------------------------- ecr --
module "ecr" {
  source = "../../modules/ecr"
  name   = "${var.project}/demo-app"
}

# ------------------------------------------------- GitHub Actions via OIDC --
module "github_oidc" {
  source = "../../modules/github-oidc"

  name                 = local.name
  github_repo          = var.github_repo
  ecr_repository_arn   = module.ecr.repository_arn
  create_oidc_provider = var.create_github_oidc_provider
}

# ------------------------------------------- Pod Identity: add-on roles --
# External Secrets Operator: read only this environment's DB secret.
module "external_secrets_identity" {
  source = "../../modules/pod-identity"

  name            = "${local.name}-external-secrets"
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadAppSecrets"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:ListSecretVersionIds",
      ]
      Resource = [module.rds.secret_arn]
    }]
  })
}

# AWS Load Balancer Controller: official policy from the upstream project.
module "lb_controller_identity" {
  source = "../../modules/pod-identity"

  name            = "${local.name}-aws-lb-controller"
  cluster_name    = module.eks.cluster_name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  policy_json     = file("${path.module}/policies/aws-load-balancer-controller.json")
}

# ------------------------------------------------------- FinOps guardrail --
resource "aws_budgets_budget" "monthly" {
  count = var.budget_alert_email == "" ? 0 : 1

  name         = "${local.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:Project$%s", var.project)] # tag must be activated as a cost-allocation tag
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
