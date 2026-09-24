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
  multi_az                      = var.db_multi_az
  publicly_accessible           = false
  deletion_protection           = var.db_deletion_protection
  backup_retention_period       = var.db_backup_retention_period
  copy_tags_to_snapshot         = true
  skip_final_snapshot           = var.db_skip_final_snapshot
  final_snapshot_identifier     = var.db_skip_final_snapshot ? null : format("%s-sqlserver-final", local.name)
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = format("%s-redis", local.name)
  subnet_ids = module.vpc.database_subnets
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = format("%s-redis", local.name)
  description                = format("Application cache for %s", local.name)
  engine                     = "redis"
  node_type                  = var.redis_node_type
  port                       = 6379
  parameter_group_name       = "default.redis7"
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [aws_security_group.redis.id]
  num_node_groups            = 1
  replicas_per_node_group    = var.redis_replicas_per_node_group
  automatic_failover_enabled = var.redis_replicas_per_node_group > 0
  multi_az_enabled           = var.redis_replicas_per_node_group > 0
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth.result
  kms_key_id                 = aws_kms_key.workload.arn
  snapshot_retention_limit   = var.redis_snapshot_retention_limit
}

resource "random_password" "redis_auth" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = format("%s/redis/auth-token", local.name)
  description             = format("Token de autenticação TLS do Redis para %s", local.name)
  kms_key_id              = aws_kms_key.workload.arn
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id     = aws_secretsmanager_secret.redis_auth.id
  secret_string = random_password.redis_auth.result
}

resource "aws_secretsmanager_secret" "backend_runtime" {
  name                    = format("%s/backend/runtime", local.name)
  description             = format("Segredos de runtime da API e do worker de %s", local.name)
  kms_key_id              = aws_kms_key.workload.arn
  recovery_window_in_days = 7
}
