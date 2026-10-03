terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.59, < 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }

  # Partial configuration: `make tf-init` supplies bucket/key/region from
  # backend.hcl, which is generated from the bootstrap outputs.
  # use_lockfile enables S3-native state locking (no DynamoDB table needed).
  backend "s3" {}
}

provider "aws" {
  region = var.region

  # Cost-allocation tags applied to every resource Terraform creates.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Repository  = var.github_repo
    }
  }
}
