variable "project_name" {
  description = "Short DNS-safe project name."
  type        = string
}

variable "environment" {
  description = "Environment identifier."
  type        = string

  validation {
    condition     = contains(["dev", "hml", "prod"], var.environment)
    error_message = "Environment must be one of: dev, hml, prod."
  }
}

variable "vpc_cidr" {
  description = "Workload VPC CIDR."
  type        = string
}

variable "single_nat_gateway" {
  description = "Whether all private subnets share one NAT gateway."
  type        = bool
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
}

variable "eks_version" {
  description = "Kubernetes minor version used by EKS."
  type        = string
}

variable "eks_instance_types" {
  description = "EC2 instance types available to the managed node group."
  type        = list(string)
}

variable "eks_capacity_type" {
  description = "EKS node group capacity type."
  type        = string

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.eks_capacity_type)
    error_message = "EKS capacity type must be ON_DEMAND or SPOT."
  }
}

variable "eks_node_min_size" {
  type = number
}

variable "eks_node_desired_size" {
  type = number
}

variable "eks_node_max_size" {
  type = number
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_max_allocated_storage" {
  type = number
}

variable "db_multi_az" {
  type = bool
}

variable "db_deletion_protection" {
  type = bool
}

variable "db_backup_retention_period" {
  type = number
}

variable "db_skip_final_snapshot" {
  type = bool
}

variable "redis_node_type" {
  type = string
}

variable "redis_replicas_per_node_group" {
  type = number
}

variable "redis_snapshot_retention_limit" {
  type = number
}

variable "alb_deletion_protection" {
  type = bool
}

variable "ecr_image_retention_count" {
  type = number
}
