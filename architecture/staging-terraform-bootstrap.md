# Plano Terraform de staging por comentário de PR

## Objetivo

Gerar somente o `terraform plan` do ambiente `hml` quando um colaborador
autorizado comentar exatamente `terraform-plan-hml` em um pull request. O
workflow não executa `apply`, não usa backend remoto e não cria infraestrutura.

## Configuração AWS

O GitHub Actions assume uma role OIDC sem chaves estáticas:

- Conta: `542561134127`.
- Região: `us-east-1`.
- Role: `tracking-hml-terraform-plan`.
- Trust: `token.actions.githubusercontent.com`, público `sts.amazonaws.com` e
  subject `repo:wellingtonfds/shipment-tracking-infra:ref:refs/heads/master`.
- Permissões: somente `ec2:DescribeAvailabilityZones` e
  `sts:GetCallerIdentity`; não há acesso a S3, DynamoDB, Route 53, WAF, ACM,
  Secrets Manager ou operações de escrita.

O ARN da role fica na variável de Actions `AWS_PLAN_ROLE_ARN`; não deve ser
versionado como segredo nem escrito em código Terraform.

O `GITHUB_TOKEN` recebe também `issues: write`, exclusivamente para reagir ao
comentário acionador; isso não amplia o acesso da role AWS.

## Gatilho e proteções

- Evento: comentário criado em issue ou PR.
- O job exige que o comentário pertença a um PR, tenha o texto exato
  `terraform-plan-hml` e tenha sido enviado por `OWNER`, `MEMBER` ou
  `COLLABORATOR`.
- O workflow consulta o PR e só executa se o branch de origem pertencer ao
  mesmo repositório; forks não recebem credenciais AWS.
- Como `issue_comment` parte do commit de `master`, o workflow consulta e faz
  checkout explícito do SHA do head do PR antes de executar Terraform.
- Ao aceitar o comando, o workflow adiciona 👀 ao comentário. Após publicar o
  artifact, adiciona 👍; se qualquer etapa falhar, adiciona 😕. As reações não
  criam comentários adicionais.

## Escopo do plano

Em `hml`, `enable_public_edge = false`. O Terraform prevê VPC, EKS, ECR, RDS,
Redis, KMS, Secrets Manager, ALB HTTP e security groups, mas não prevê ACM,
Route 53, WAF, domínio, DNS ou listener HTTPS.

O backend S3 declarado no repositório requer inicialização para permitir um
plano. Como esta etapa não cria o backend, o workflow copia o checkout para
um diretório temporário e remove apenas o bloco `backend "s3" {}` da cópia.
O código versionado não é alterado por esse procedimento.

Na cópia temporária, o workflow executa:

```bash
terraform -chdir=deployment init -input=false
terraform -chdir=deployment validate
terraform -chdir=deployment plan -refresh=false -no-color \
  -var-file=../environments/hml.tfvars -out=hml.tfplan
```

O texto renderizado do plano é publicado como artifact por sete dias. O arquivo
binário do plano não é publicado nem versionado, pois pode conter valores
sensíveis.
