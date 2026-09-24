output "ecr_repository_url" {
  description = "ECR repository for immutable backend images."
  value       = module.platform.ecr_repository_url
}

output "eks_cluster_name" {
  description = "EKS cluster receiving the application deployment."
  value       = module.platform.eks_cluster_name
}

output "deployment_contract" {
  description = "Stable Kubernetes names consumed by the backend deployment action."
  value = {
    namespace             = "tracking"
    api_deployment        = "tracking-api"
    api_container         = "tracking-api"
    worker_deployment     = "tracking-worker"
    worker_container      = "tracking-worker"
    service               = "tracking-api"
    target_group_binding  = "tracking-api"
    service_account       = "tracking-backend"
    secret_provider_class = "tracking-backend-secrets"
    config_map            = "tracking-runtime-config"
  }
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

output "redis_auth_secret_arn" {
  description = "ARN do Secrets Manager com o token Redis; sincronize-o no namespace Kubernetes de tracking."
  value       = module.platform.redis_auth_secret_arn
}

output "backend_runtime_secret_arn" {
  description = "Secrets Manager secret to populate before enabling application replicas."
  value       = module.platform.backend_runtime_secret_arn
}

output "load_balancer_controller_role_arn" {
  description = "Pod Identity role for the AWS Load Balancer Controller."
  value       = module.platform.load_balancer_controller_role_arn
}

output "backend_pod_identity_role_arn" {
  description = "Pod Identity role for the API and worker service account."
  value       = module.platform.backend_pod_identity_role_arn
}
