locals {
  application_domain = var.enable_public_edge ? (
    var.environment == "prod" ? format("api.%s", var.hosted_zone_name) : format("api-%s.%s", var.environment, var.hosted_zone_name)
  ) : null
}

module "platform" {
  source = "../modules/platform"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.environment_config.vpc_cidr
  single_nat_gateway = var.environment_config.single_nat_gateway
  hosted_zone_name   = var.hosted_zone_name
  application_domain = local.application_domain
  enable_public_edge = var.enable_public_edge
  allowed_api_cidrs  = var.allowed_api_cidrs

  eks_version           = var.environment_config.eks.version
  eks_instance_types    = var.environment_config.eks.instance_types
  eks_capacity_type     = var.environment_config.eks.capacity_type
  eks_node_min_size     = var.environment_config.eks.min_size
  eks_node_desired_size = var.environment_config.eks.desired_size
  eks_node_max_size     = var.environment_config.eks.max_size

  db_instance_class          = var.environment_config.database.instance_class
  db_allocated_storage       = var.environment_config.database.allocated_storage
  db_max_allocated_storage   = var.environment_config.database.max_allocated_storage
  db_multi_az                = var.environment_config.database.multi_az
  db_deletion_protection     = var.environment_config.database.deletion_protection
  db_backup_retention_period = var.environment_config.database.backup_retention_period
  db_skip_final_snapshot     = var.environment_config.database.skip_final_snapshot

  redis_node_type                = var.environment_config.redis.node_type
  redis_replicas_per_node_group  = var.environment_config.redis.replicas_per_node_group
  redis_snapshot_retention_limit = var.environment_config.redis.snapshot_retention_limit
  alb_deletion_protection        = var.environment_config.alb_deletion_protection
  ecr_image_retention_count      = var.environment_config.ecr_image_retention_count
  application_log_retention_days = var.environment_config.application_log_retention_days
}
