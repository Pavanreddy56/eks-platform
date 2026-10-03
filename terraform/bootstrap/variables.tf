variable "project" {
  description = "Project name, used as a prefix for the state bucket"
  type        = string
  default     = "eks-platform"
}

variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "ap-south-1"
}

variable "force_destroy" {
  description = "Allow deleting the bucket even when it contains state files"
  type        = bool
  default     = false
}
