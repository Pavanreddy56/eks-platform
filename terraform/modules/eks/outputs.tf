output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "node_security_group_id" {
  description = "Security group attached to worker nodes (and pods)"
  value       = module.eks.node_security_group_id
}
