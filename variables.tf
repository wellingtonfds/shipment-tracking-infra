variable "aws_region" {
  description = "AWS deployment region."
  type        = string
}

variable "project_name" {
  description = "Short DNS-safe project name."
  type        = string
  default     = "tracking"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "Workload VPC CIDR."
  type        = string
  default     = "10.40.0.0/16"
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 zone, without trailing dot."
  type        = string
}

variable "application_domain" {
  description = "Public fully qualified API hostname."
  type        = string
}

variable "allowed_api_cidrs" {
  description = "Networks permitted at the public HTTPS listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "db_instance_class" {
  type    = string
  default = "db.m6i.xlarge"
}

variable "db_allocated_storage" {
  type    = number
  default = 1024
}

variable "db_max_allocated_storage" {
  type    = number
  default = 4096
}

variable "redis_node_type" {
  type    = string
  default = "cache.r6g.large"
}
