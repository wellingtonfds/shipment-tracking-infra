resource "aws_kms_key" "workload" {
  description             = format("Encryption key for %s", local.name)
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "workload" {
  name          = format("alias/%s-workload", local.name)
  target_key_id = aws_kms_key.workload.key_id
}

resource "aws_security_group" "alb" {
  name   = format("%s-alb", local.name)
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_api_cidrs
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "database" {
  name   = format("%s-database", local.name)
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "redis" {
  name   = format("%s-redis", local.name)
  vpc_id = module.vpc.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "database_from_eks" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                    = 1433
  to_port                      = 1433
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}
