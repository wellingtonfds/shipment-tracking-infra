# Tracking infrastructure

Infraestrutura AWS do backend de rastreamento, gerenciada pelo mesmo código Terraform para os ambientes `dev`, `hml` e `prod`. Cada ambiente possui VPC, ECR, EKS, RDS SQL Server, Redis, ALB, WAF, certificado e DNS próprios, além de estado Terraform isolado.

## Organização

```text
deployment/       root module executado pelo Terraform
environments/     perfis de capacidade e chaves de estado por ambiente
modules/platform/ implementação reutilizável da plataforma
kubernetes/       manifesto complementar da aplicação
architecture/     diagrama e decisões de arquitetura
```

Os recursos existem somente em `modules/platform`. Os arquivos `.tfvars` alteram capacidade, disponibilidade, retenção e proteções sem copiar blocos de recursos.

| Ambiente | DNS              | Perfil                                            |
| -------- | ---------------- | ------------------------------------------------- |
| `dev`    | `api-dev.<zona>` | Spot, um nó inicial, um NAT, dados Single-AZ      |
| `hml`    | `api-hml.<zona>` | On-Demand, um nó inicial, um NAT, dados Single-AZ |
| `prod`   | `api.<zona>`     | Dois nós, NAT por AZ, RDS e Redis Multi-AZ        |

## Pré-requisitos

O bucket S3 do estado, a tabela DynamoDB de lock, a zona pública Route 53 e a role OIDC de planejamento são externos a esta configuração. O bucket deve ter versionamento habilitado.

Crie GitHub Environments chamados `dev`, `hml` e `prod` e configure nestes ambientes:

- `AWS_REGION`
- `AWS_PLAN_ROLE_ARN`
- `TF_STATE_BUCKET`
- `TF_STATE_LOCK_TABLE`
- `HOSTED_ZONE_NAME`
- `ALLOWED_API_CIDRS`, como lista JSON dos CIDRs autorizados no listener publico da API e no endpoint publico do EKS, por exemplo `["198.51.100.0/24"]`.

O workflow valida o código uma vez e executa `terraform plan` para os três ambientes. Ele não executa `apply`.

## Uso local

Defina as variáveis comuns:

```bash
export TF_VAR_aws_region="us-east-1"
export TF_VAR_hosted_zone_name="example.com"
export TF_VAR_allowed_api_cidrs='["198.51.100.0/24"]'
```

Valide sem acessar o estado remoto:

```bash
terraform -chdir=deployment init -backend=false
terraform fmt -check -recursive
terraform -chdir=deployment validate
```

Inicialize e gere o plano de um ambiente:

```bash
terraform -chdir=deployment init -reconfigure \
  -backend-config=../environments/dev.backend.hcl \
  -backend-config="bucket=SEU_BUCKET" \
  -backend-config="region=$TF_VAR_aws_region" \
  -backend-config="dynamodb_table=SUA_TABELA_DE_LOCK" \
  -backend-config="encrypt=true"

terraform -chdir=deployment plan -var-file=../environments/dev.tfvars
```

Troque `dev` por `hml` ou `prod` para operar outro ambiente. Sempre reinicialize com o backend correspondente antes de planejar ou aplicar.

## Custos e disponibilidade

Dev mantém os mesmos serviços de produção para reduzir diferenças funcionais, mas usa um NAT Gateway, nós Spot, SQL Server e Redis mínimos, armazenamento reduzido e recursos Single-AZ. O control plane do EKS, o SQL Server Standard, o NAT Gateway, o ALB e o WAF continuam gerando custos fixos enquanto o ambiente existir.

Homologação usa nós On-Demand, mas permanece Single-AZ e com somente um NAT. Produção mantém redundância entre duas zonas, backups longos e proteção contra exclusão.

## Contrato com o backend

Cada ambiente publica imagens no seu próprio ECR e implanta no EKS correspondente. O Deployment deve definir requests e limits de CPU, usar o endpoint `/health` e consumir o target group exportado pelo Terraform por meio de um `TargetGroupBinding`.

O manifesto [kubernetes/tracking-api-autoscaling.yaml](kubernetes/tracking-api-autoscaling.yaml) mantém de duas a seis réplicas, configura o dispatcher do outbox e usa `/api/v1/health` nas sondas. O manifesto [kubernetes/tracking-worker.yaml](kubernetes/tracking-worker.yaml) executa `node dist/worker.js`, mantém de duas a oito réplicas e define probes e recursos. Em dev e hml, o único nó inicial pode concentrar as réplicas até que o node group aumente.

RDS e Redis não têm endereço público. Redis usa TLS e token de autenticação aleatório, gerenciado em Secrets Manager; o Terraform expõe somente o ARN do segredo. Sincronize o token para `REDIS_PASSWORD` no segredo Kubernetes `tracking-backend-secrets`. Esse segredo também fornece `DATABASE_URL`, `JWT_SECRET` e, quando configurado, `GEOCODER_API_KEY`. Não grave valores secretos em manifests.

O token Redis também fica no estado Terraform. Mantenha o backend S3 com criptografia habilitada e acesso restrito, além do versionamento recomendado acima.

Crie `tracking-runtime-config` no namespace `tracking` com pelo menos `REDIS_HOST` (valor de `terraform output -raw redis_primary_endpoint`). Também pode configurar `GEOCODER_URL`, `GEOCODER_USER_AGENT`, `GEOCODE_RATE_LIMIT`, `GEOCODER_CACHE_TTL_SECONDS`, `TRACKING_WORKER_CONCURRENCY` e `DLQ_REPLAY_INTERVAL_MS`. O dispatcher fica nas réplicas da API; só o deployment worker consome a fila. O outbox SQL permite recuperar itens pendentes depois de uma interrupção do Redis.

Os autoscalers usam CPU. A validação deste repositório não aplica recursos:

```bash
terraform -chdir=deployment init -backend=false
terraform fmt -check -recursive
terraform -chdir=deployment validate
```

Veja a arquitetura em [architecture/architecture.md](architecture/architecture.md).
