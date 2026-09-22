# Tracking infrastructure

Infraestrutura AWS de produção para o backend de rastreamento: EKS distribuído em duas zonas, ECR, RDS SQL Server Multi-AZ, Redis com failover Multi-AZ, ALB HTTPS, WAF, Route 53, KMS e Secrets Manager.

## Organização

Todos os arquivos `.tf` na raiz formam um único módulo Terraform e usam o mesmo estado. A divisão por arquivos melhora a navegação, mas não cria stacks independentes nem altera os endereços dos recursos.

| Arquivo | Responsabilidade |
| --- | --- |
| `provider.tf` | Provider AWS, tags padrão, zona Route 53 e zonas de disponibilidade |
| `network.tf` | VPC, sub-redes públicas, privadas e de dados, NAT e tags do EKS |
| `security.tf` | KMS e regras de rede entre borda, EKS, SQL Server e Redis |
| `registry.tf` | ECR, scan e retenção de imagens |
| `eks.tf` | IAM, cluster EKS e grupo de nós |
| `data.tf` | RDS SQL Server Multi-AZ e ElastiCache Redis |
| `edge.tf` | ACM, Route 53, ALB, target group, listener e WAF |

O diretório `.terraform/modules/vpc` é um cache local baixado pelo `terraform init` para o módulo público `terraform-aws-modules/vpc/aws`. Seus exemplos, README e fontes não pertencem a este projeto, não são versionados e podem ser recriados pelo init.

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
## Autoscaling de pods

O manifesto [kubernetes/tracking-api-autoscaling.yaml](kubernetes/tracking-api-autoscaling.yaml) define o HPA do Deployment `tracking-api` no namespace `tracking`: mínimo de 2, máximo de 6 e CPU média alvo de 60%. O scale-up permite até dois pods por minuto; o scale-down aguarda cinco minutos para evitar oscilações.

O Deployment deve definir `resources.requests.cpu` e `resources.limits.cpu`. A métrica percentual do HPA é calculada contra o request de CPU. O patch também exige distribuição por zona com `maxSkew: 1`; se faltar capacidade em uma zona, o pod permanece pendente, pois esta etapa não cria nós EC2 adicionais.
