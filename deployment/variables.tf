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
  description = "Environment identifier."
  type        = string

  validation {
    condition     = contains(["dev", "hml", "prod"], var.environment)
    error_message = "Environment must be one of: dev, hml, prod."
  }
}

variable "hosted_zone_name" {
  description = "Existing public Route 53 zone, without trailing dot."
  type        = string
}

variable "allowed_api_cidrs" {
  description = "Networks permitted at the public HTTPS listener."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "environment_config" {
  description = "Capacity, availability and retention profile for one environment."
  type = object({
    vpc_cidr           = string
    single_nat_gateway = bool
    eks = object({
      version        = string
      instance_types = list(string)
      capacity_type  = string
      min_size       = number
      desired_size   = number
      max_size       = number
    })
    database = object({
      instance_class          = string
      allocated_storage       = number
      max_allocated_storage   = number
      multi_az                = bool
      deletion_protection     = bool
      backup_retention_period = number
      skip_final_snapshot     = bool
    })
    redis = object({
      node_type                = string
      replicas_per_node_group  = number
      snapshot_retention_limit = number
    })
    alb_deletion_protection   = bool
    ecr_image_retention_count = number
  })

  validation {
    condition = (
      var.environment_config.eks.min_size <= var.environment_config.eks.desired_size &&
      var.environment_config.eks.desired_size <= var.environment_config.eks.max_size
    )
    error_message = "EKS node sizes must satisfy min_size <= desired_size <= max_size."
  }

  validation {
    condition = (
      var.environment_config.database.allocated_storage <=
      var.environment_config.database.max_allocated_storage
    )
    error_message = "Database allocated storage cannot exceed max allocated storage."
  }
}
