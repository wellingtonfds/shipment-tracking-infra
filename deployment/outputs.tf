output "ecr_repository_url" {
  description = "ECR repository for immutable backend images."
  value       = module.platform.ecr_repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster receiving the application deployment."
  value       = module.platform.eks_cluster_name
}

output "application_target_group_arn" {
  description = "Target group consumed by the TargetGroupBinding."
  value       = module.platform.application_target_group_arn
}

output "application_url" {
  description = "Public HTTPS endpoint."
  value       = module.platform.application_url
}

output "sqlserver_endpoint" {
  description = "Private SQL Server endpoint."
  value       = module.platform.sqlserver_endpoint
}

output "sqlserver_master_secret_arn" {
  description = "RDS-managed master secret. Grant access only with workload IAM."
  value       = module.platform.sqlserver_master_secret_arn
}

output "redis_primary_endpoint" {
  description = "Private primary Redis endpoint."
  value       = module.platform.redis_primary_endpoint
}
