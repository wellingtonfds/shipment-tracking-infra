resource "aws_db_subnet_group" "database" {
  name       = format("%s-database", local.name)
  subnet_ids = module.vpc.database_subnets
}

resource "aws_db_instance" "sqlserver" {
  identifier                    = format("%s-sqlserver", local.name)
  engine                        = "sqlserver-se"
  license_model                 = "license-included"
  instance_class                = var.db_instance_class
  allocated_storage             = var.db_allocated_storage
  max_allocated_storage         = var.db_max_allocated_storage
  storage_type                  = "gp3"
  storage_encrypted             = true
  kms_key_id                    = aws_kms_key.workload.arn
  db_subnet_group_name          = aws_db_subnet_group.database.name
  vpc_security_group_ids        = [aws_security_group.database.id]
  username                      = "dbadmin"
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.workload.arn
  multi_az                      = true
  publicly_accessible           = false
  deletion_protection           = true
  backup_retention_period       = 35
  copy_tags_to_snapshot         = true
  skip_final_snapshot           = false
  final_snapshot_identifier     = format("%s-sqlserver-final", local.name)
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = format("%s-redis", local.name)
  subnet_ids = module.vpc.database_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = format("%s-redis", local.name)
  description                = "Highly available application cache"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  num_node_groups            = 1
  replicas_per_node_group    = 1
  automatic_failover_enabled = true
  multi_az_enabled           = true
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  kms_key_id                 = aws_kms_key.workload.arn
  snapshot_retention_limit   = 7
}
