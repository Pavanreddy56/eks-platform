output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EKS nodes)"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs (internet-facing load balancers)"
  value       = module.vpc.public_subnets
}

output "database_subnet_group_name" {
  description = "RDS subnet group name"
  value       = module.vpc.database_subnet_group_name
}
