output "ecr_repository_url" {
  description = "ECR repository for immutable backend images."
  value       = aws_ecr_repository.application.repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster receiving the application deployment."
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint used by the Helm provider after the cluster exists."
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64-encoded cluster CA used by the Helm provider."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "vpc_id" {
  description = "VPC used by the AWS Load Balancer Controller."
  value       = module.vpc.vpc_id
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

output "backend_runtime_secret_arn" {
  description = "Secrets Manager container populated out of band with backend runtime keys."
  value       = aws_secretsmanager_secret.backend_runtime.arn
}

output "load_balancer_controller_role_arn" {
  description = "Pod Identity role used by the AWS Load Balancer Controller."
  value       = aws_iam_role.pod_identity_load_balancer_controller.arn
}

output "backend_pod_identity_role_arn" {
  description = "Pod Identity role used by the application to read its runtime secret."
  value       = aws_iam_role.pod_identity_backend.arn
}
