variable "name" {
  description = "Repository name"
  type        = string
}

variable "force_delete" {
  description = "Delete the repository even if it contains images"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Extra tags"
  type        = map(string)
  default     = {}
}
