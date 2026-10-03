variable "project" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "eks-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner tag value (your name or email)"
  type        = string
}

variable "cost_center" {
  description = "Cost-center tag value"
  type        = string
  default     = "portfolio"
}

variable "github_repo" {
  description = "GitHub repository allowed to push images, in owner/name form"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Set false if the AWS account already has the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to reduce cost"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version. Check `aws eks describe-cluster-versions` and choose one in standard support."
  type        = string
  default     = "1.35"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the EKS API. Set to your own IP, e.g. [\"203.0.113.10/32\"]."
  type        = list(string)
}

variable "node_instance_types" {
  description = "Node instance types (multiple types improve Spot availability)"
  type        = list(string)
  default     = ["t3.large", "t3a.large", "m5.large", "m6i.large"]
}

variable "node_capacity_type" {
  description = "SPOT for dev cost savings, ON_DEMAND for stability"
  type        = string
  default     = "SPOT"
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Initial node count"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "monthly_budget_usd" {
  description = "Monthly budget for this project's tagged resources"
  type        = number
  default     = 50
}

variable "budget_alert_email" {
  description = "Email for budget alerts. Leave empty to skip creating the budget."
  type        = string
  default     = ""
}
