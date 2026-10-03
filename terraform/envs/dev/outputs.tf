output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "configure_kubectl" {
  description = "Command to point kubectl at the cluster"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  description = "ECR repository for the demo app image"
  value       = module.ecr.repository_url
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN repository variable in GitHub"
  value       = module.github_oidc.role_arn
}

output "db_endpoint" {
  description = "RDS PostgreSQL endpoint (private)"
  value       = module.rds.endpoint
}

output "db_secret_name" {
  description = "Secrets Manager secret holding DB connection details"
  value       = module.rds.secret_name
}
