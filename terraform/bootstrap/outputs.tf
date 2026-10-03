output "state_bucket" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = aws_s3_bucket.state.bucket
}

output "region" {
  description = "Region of the state bucket"
  value       = var.region
}
