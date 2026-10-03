variable "name" {
  description = "Name prefix for network resources"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (cheaper, not highly available)"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Send VPC flow logs to CloudWatch"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags for network resources"
  type        = map(string)
  default     = {}
}
