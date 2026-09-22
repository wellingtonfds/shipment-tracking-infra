environment = "prod"

environment_config = {
  vpc_cidr           = "10.60.0.0/16"
  single_nat_gateway = false

  eks = {
    version        = "1.35"
    instance_types = ["m6i.large"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    desired_size   = 2
    max_size       = 6
  }

  database = {
    instance_class          = "db.m6i.xlarge"
    allocated_storage       = 1024
    max_allocated_storage   = 4096
    multi_az                = true
    deletion_protection     = true
    backup_retention_period = 35
    skip_final_snapshot     = false
  }

  redis = {
    node_type                = "cache.r6g.large"
    replicas_per_node_group  = 1
    snapshot_retention_limit = 7
  }

  alb_deletion_protection   = true
  ecr_image_retention_count = 30
}
