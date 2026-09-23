output "ecr_repository_url" {
  description = "ECR repository for immutable backend images."
  value       = aws_ecr_repository.application.repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster receiving the application deployment."
  value       = aws_eks_cluster.this.name
}

output "application_target_group_arn" {
  description = "Target group consumed by the TargetGroupBinding."
  value       = aws_lb_target_group.application.arn
}

output "application_url" {
  description = "Public application endpoint."
  value       = var.enable_public_edge ? format("https://%s", var.application_domain) : format("http://%s", aws_lb.application.dns_name)
}

output "sqlserver_endpoint" {
  description = "Private SQL Server endpoint."
  value       = aws_db_instance.sqlserver.address
}

output "sqlserver_master_secret_arn" {
  description = "RDS-managed master secret ARN."
  value       = aws_db_instance.sqlserver.master_user_secret[0].secret_arn
}

output "redis_primary_endpoint" {
  description = "Private primary Redis endpoint."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_auth_secret_arn" {
  description = "ARN do Secrets Manager com o token TLS do Redis para sincronização do segredo Kubernetes."
  value       = aws_secretsmanager_secret.redis_auth.arn
}
