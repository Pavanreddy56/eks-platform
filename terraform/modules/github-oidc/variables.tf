variable "name" {
  description = "Name prefix for the IAM role"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository in owner/name form"
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo must look like owner/repository."
  }
}

variable "ecr_repository_arn" {
  description = "ECR repository the workflow may push to"
  type        = string
}

variable "create_oidc_provider" {
  description = "Set false if the account already has the GitHub OIDC provider"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
