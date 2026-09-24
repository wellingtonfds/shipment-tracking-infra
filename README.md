# Tracking infrastructure

Infraestrutura AWS do backend de rastreamento, gerenciada pelo mesmo código Terraform para os ambientes `dev`, `hml` e `prod`. O staging (`hml`) pode ser planejado sem criar estado remoto, domínio, Route 53, WAF ou certificado.

## Organização

```text
deployment/       root module executado pelo Terraform
environments/     perfis de capacidade e chaves de estado por ambiente
modules/platform/ implementação reutilizável da plataforma
kubernetes/       chart Helm com a baseline completa dos workloads
architecture/     diagrama e decisões de arquitetura
docs/             ADRs e documentação operacional de deployment
```

Os recursos existem somente em `modules/platform`. Os arquivos `.tfvars` alteram capacidade, disponibilidade, retenção e proteções sem copiar blocos de recursos.

| Ambiente | DNS              | Perfil                                            |
| -------- | ---------------- | ------------------------------------------------- |
| `dev`    | `api-dev.<zona>` | Spot, um nó inicial, um NAT, dados Single-AZ      |
| `hml`    | DNS do ALB HTTP  | On-Demand, um nó inicial, um NAT, dados Single-AZ |
| `prod`   | `api.<zona>`     | Dois nós, NAT por AZ, RDS e Redis Multi-AZ        |

## Pré-requisitos

O bucket S3 do estado, a tabela DynamoDB de lock e a zona pública Route 53 continuam externos a esta configuração para os ambientes que usam a borda pública. O plano automatizado de `hml` não usa backend remoto.

Para executar o plano de `hml` por GitHub Actions, configure a variável de repositório:

- `AWS_PLAN_ROLE_ARN`

Comente exatamente `terraform-plan-hml` em um PR interno como `OWNER`, `MEMBER` ou `COLLABORATOR`. O workflow adiciona 👀 ao aceitar o comando, 👍 após concluir e 😕 se falhar. Ele busca o head do PR, inicializa uma cópia temporária sem backend S3, valida e gera apenas o `terraform plan` de `hml`. O artifact do plano permanece disponível por sete dias; o workflow nunca executa `apply`.

Todo PR contra `master` executa `Terraform validate`, sem credenciais AWS ou
backend remoto. Esse check é obrigatório para mesclar alterações em `master`.

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

Cada ambiente publica imagens no seu próprio ECR e recebe a aplicação no EKS correspondente. Este repositório controla o chart Helm completo da baseline: namespace, identidade, segredos, Deployments, probes, recursos, segurança, Service e `TargetGroupBinding`. Os Deployments nascem com zero réplicas e imagem placeholder; não há HPA neste repositório.

O backend controla somente o ConfigMap não secreto, a imagem imutável, a ativação das réplicas e os HPAs. Os nomes estáveis e o fluxo operacional completo estão em [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md).

RDS e Redis não têm endereço público. O Pod Identity Agent e o ASCP integram o Secrets Manager aos pods sem credenciais estáticas, e o Metrics Server fornece as métricas usadas pelos HPAs. Valores secretos não são gravados no chart nem expostos em outputs.

Veja também a [arquitetura multiambiente](architecture/architecture.md), o
[ADR de Kubernetes](docs/adr/0001.md) e o
[ADR de modelo de compute](docs/adr/0002.md).
