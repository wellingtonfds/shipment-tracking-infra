# Tracking infrastructure

Infraestrutura AWS de produção para o backend de rastreamento: EKS distribuído em duas zonas, ECR, RDS SQL Server Multi-AZ, Redis com failover Multi-AZ, ALB HTTPS, WAF, Route 53, KMS e Secrets Manager.

## Escopo inicial

O workflow somente valida e gera o plano Terraform. Ele não executa `apply`.

O bucket S3 do estado, a tabela DynamoDB de lock e a role OIDC de planejamento são pré-requisitos externos. Configure as variáveis do repositório: `AWS_REGION`, `AWS_PLAN_ROLE_ARN`, `TF_STATE_BUCKET`, `TF_STATE_KEY`, `TF_STATE_LOCK_TABLE`, `HOSTED_ZONE_NAME`, `APPLICATION_DOMAIN` e `ALLOWED_API_CIDRS`.

Use uma role OIDC exclusiva, com permissão de leitura para o estado e recursos consultados pelo plano; ela não deve ter permissões de alteração.

## Validação local

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init -backend=false
terraform fmt -check -recursive
terraform validate
```

## Contrato com o backend

O pipeline da aplicação publica imagens imutáveis no ECR e faz o deploy no EKS. O deployment deve usar no mínimo duas réplicas, `topologySpreadConstraints`, HPA e o endpoint `/health`. Um `TargetGroupBinding` do AWS Load Balancer Controller deve consumir o ARN exportado pelo Terraform. Somente a identidade IAM do workload deve ler o segredo gerenciado pelo RDS.

RDS e Redis não têm IP público. A aplicação mantém o isolamento lógico dos clientes e o particionamento da tabela de eventos; a infraestrutura reforça o isolamento com rede, IAM, criptografia e segredos.

Veja a arquitetura em [architecture/architecture.md](architecture/architecture.md).
