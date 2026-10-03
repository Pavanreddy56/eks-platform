variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes minor version. Pick one in EKS standard support."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the control plane ENIs and nodes"
  type        = list(string)
}

variable "endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint"
  type        = list(string)
}

variable "node_instance_types" {
  description = "Instance types for the node group (several types improve Spot availability)"
  type        = list(string)
}

variable "node_capacity_type" {
  description = "ON_DEMAND or SPOT"
  type        = string
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_min_size" {
  description = "Minimum node count"
  type        = number
}

variable "node_max_size" {
  description = "Maximum node count"
  type        = number
}

variable "node_desired_size" {
  description = "Initial node count"
  type        = number
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
