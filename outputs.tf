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
  description = "Public HTTPS endpoint."
  value       = format("https://%s", var.application_domain)
}

output "sqlserver_endpoint" {
  description = "Private SQL Server endpoint."
  value       = aws_db_instance.sqlserver.address
}

output "sqlserver_master_secret_arn" {
  description = "RDS-managed master secret. Grant access only with workload IAM."
  value       = aws_db_instance.sqlserver.master_user_secret[0].secret_arn
}

output "redis_primary_endpoint" {
  description = "Private primary Redis endpoint."
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

