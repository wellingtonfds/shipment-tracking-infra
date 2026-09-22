environment = "dev"

environment_config = {
  vpc_cidr           = "10.40.0.0/16"
  single_nat_gateway = true

  eks = {
    version        = "1.35"
    instance_types = ["t3.medium", "t3a.medium"]
    capacity_type  = "SPOT"
    min_size       = 1
    desired_size   = 1
    max_size       = 2
  }

  database = {
    instance_class          = "db.t3.xlarge"
    allocated_storage       = 20
    max_allocated_storage   = 100
    multi_az                = false
    deletion_protection     = false
    backup_retention_period = 1
    skip_final_snapshot     = true
  }

  redis = {
    node_type                = "cache.t4g.micro"
    replicas_per_node_group  = 0
    snapshot_retention_limit = 1
  }

  alb_deletion_protection   = false
  ecr_image_retention_count = 10
}
