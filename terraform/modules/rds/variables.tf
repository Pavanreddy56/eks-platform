variable "name" {
  description = "Identifier prefix for the database"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group (isolated database subnets)"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432"
  type        = list(string)
}

variable "engine_major_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "appadmin"
}

variable "multi_az" {
  description = "Deploy a standby in a second AZ"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy (dev only)"
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Secrets Manager secret name for connection details"
  type        = string
}

variable "secret_recovery_window_days" {
  description = "0 deletes the secret immediately on destroy (handy for dev)"
  type        = number
  default     = 0
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
