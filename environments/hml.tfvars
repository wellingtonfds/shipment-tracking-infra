environment        = "hml"
enable_public_edge = false

environment_config = {
  vpc_cidr           = "10.50.0.0/16"
  single_nat_gateway = true

  eks = {
    version        = "1.35"
    instance_types = ["t3.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    desired_size   = 1
    max_size       = 3
  }

  database = {
    instance_class          = "db.t3.xlarge"
    allocated_storage       = 100
    max_allocated_storage   = 500
    multi_az                = false
    deletion_protection     = false
    backup_retention_period = 7
    skip_final_snapshot     = true
  }

  redis = {
    node_type                = "cache.t4g.small"
    replicas_per_node_group  = 0
    snapshot_retention_limit = 7
  }

  alb_deletion_protection        = false
  ecr_image_retention_count      = 20
  application_log_retention_days = 30
}
