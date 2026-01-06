# Variables for AWS Development Environment

variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID (will be auto-detected if not provided)"
  type        = string
  default     = ""
}

variable "enable_arm_instances" {
  description = "Use ARM-based instances where possible for cost savings"
  type        = bool
  default     = true
}

variable "spot_instances_enabled" {
  description = "Use spot instances for non-critical workloads"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false  # Disabled in dev to save costs
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster API"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production!
}
