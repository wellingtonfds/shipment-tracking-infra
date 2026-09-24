# Preparação da plataforma para deployment

Este documento é a fonte de verdade da baseline operacional que a infraestrutura entrega antes da action do backend. O Terraform controla a plataforma AWS, os add-ons e o chart Helm completo dos workloads. O backend altera posteriormente apenas ConfigMap, imagem, réplicas e HPAs.

## O que deve existir antes da action

Uma aplicação completa da infraestrutura deve disponibilizar:

- cluster e node group EKS;
- add-on `eks-pod-identity-agent`;
- add-on `aws-secrets-store-csi-driver-provider`, que inclui ASCP e Secrets Store CSI Driver;
- add-on comunitário `metrics-server`, necessário para os HPAs de CPU;
- AWS Load Balancer Controller instalado por Helm, com Pod Identity própria;
- segredo de runtime no Secrets Manager, preenchido antes da ativação dos pods;
- namespace `tracking`;
- ServiceAccount `tracking-backend` associado por EKS Pod Identity à leitura do segredo;
- `SecretProviderClass` `tracking-backend-secrets`;
- Deployments `tracking-api` e `tracking-worker`;
- Service e `TargetGroupBinding` `tracking-api`.

O chart [tracking-baseline](../kubernetes/tracking-baseline/Chart.yaml) é aplicado pelo recurso `helm_release.tracking_baseline`. Ele não contém HPAs nem um ConfigMap de runtime: esses dois recursos são responsabilidade da action do backend.

## Contrato entre os repositórios

| Recurso                        | Nome estável                          |
| ------------------------------ | ------------------------------------- |
| Namespace                      | `tracking`                            |
| Deployment/container da API    | `tracking-api` / `tracking-api`       |
| Deployment/container do worker | `tracking-worker` / `tracking-worker` |
| Service                        | `tracking-api`                        |
| TargetGroupBinding             | `tracking-api`                        |
| ServiceAccount                 | `tracking-backend`                    |
| SecretProviderClass            | `tracking-backend-secrets`            |
| Secret Kubernetes sincronizado | `tracking-backend-secrets`            |
| ConfigMap futuro               | `tracking-runtime-config`             |

O output `deployment_contract` expõe os mesmos nomes para a automação futura. Renomear qualquer item exige uma mudança coordenada com as entradas da action do backend.

## Deployments inicialmente inativos

Os dois Deployments usam `replicas: 0` e a imagem placeholder válida `public.ecr.aws/docker/library/node:24.21.0-bookworm-slim`. Assim, a aplicação da plataforma não cria pods que tentariam iniciar sem ConfigMap, segredo preenchido ou imagem da aplicação. A action do backend troca a imagem por um digest imutável, aplica os HPAs e escala cada Deployment para o mínimo configurado.

A baseline define:

- execução como UID/GID não root, `RuntimeDefault`, filesystem raiz somente leitura, sem elevação de privilégio e sem capabilities Linux;
- `emptyDir` em `/tmp` e volume CSI somente leitura para ativar a sincronização do segredo;
- requests de `250m` CPU e `512Mi`, limits de `1` CPU e `1Gi`;
- distribuição por `topology.kubernetes.io/zone`;
- rolling update sem indisponibilidade e encerramento gracioso de 60 segundos;
- API com `node dist/main.js`, porta `3000` e probes em `/api/v1/health`;
- worker com `node dist/worker.js` e probes pelo heartbeat `/tmp/tracking-worker-health`;
- papéis distintos: API despacha o outbox e worker consome a fila.

## Service, target group e health check

O Service `tracking-api` encaminha a porta `3000` para a porta nomeada `http` do container. O `TargetGroupBinding` registra os IPs dos pods no target group criado pelo Terraform. O target group também usa porta `3000`, target type `ip` e health check `/api/v1/health`.

O namespace habilita o readiness gate do AWS Load Balancer Controller. Assim, quando houver pods, o rollout só os considera prontos depois do health check do target group.

## Fluxo de segredos

```text
Secrets Manager (tracking-<ambiente>/backend/runtime)
  → IAM role de Pod Identity restrita ao segredo e à chave KMS
  → associação EKS: tracking/tracking-backend
  → ASCP + Secrets Store CSI Driver
  → SecretProviderClass tracking-backend-secrets
  → Secret Kubernetes tracking-backend-secrets
  → envFrom da API e do worker
```

O Terraform cria o contêiner do segredo, mas não grava seus valores. Antes de ativar os Deployments, um operador autorizado deve cadastrar um JSON com todas as chaves abaixo, mantendo `GEOCODER_API_KEY` como string vazia quando não for usada:

```json
{
  "DATABASE_URL": "sqlserver://...",
  "JWT_SECRET": "...",
  "REDIS_PASSWORD": "...",
  "GEOCODER_API_KEY": ""
}
```

O acesso segue a integração oficial de [Secrets Manager com pods EKS](https://docs.aws.amazon.com/eks/latest/userguide/manage-secrets.html): a workload usa Pod Identity, e o ASCP lê somente o segredo autorizado. Valores secretos não aparecem nos manifests ou outputs. O valor do token Redis continua sendo gerenciado separadamente pelo Terraform; a automação autorizada que preencher o segredo de runtime deve copiá-lo sem expô-lo em logs.

## Outputs para automação

Além dos endpoints já existentes, o root module publica:

- `eks_cluster_name` e `ecr_repository_url`;
- `application_target_group_arn`;
- `backend_runtime_secret_arn`;
- `load_balancer_controller_role_arn`;
- `backend_pod_identity_role_arn`;
- `deployment_contract`.

Esses outputs permitem a uma automação futura autenticar no cluster, localizar registry/segredo e invocar a action do backend sem redescobrir nomes internos.

## Validação exclusivamente local

Os comandos desta seção não aplicam recursos:

```bash
terraform fmt -check -recursive
terraform -chdir=deployment init -backend=false -input=false
terraform -chdir=deployment validate

helm lint kubernetes/tracking-baseline \
  --set awsRegion=us-east-1 \
  --set backendSecretArn=arn:aws:secretsmanager:us-east-1:111122223333:secret:tracking-test/backend/runtime-AbCdEf \
  --set targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:111122223333:targetgroup/tracking-test-api/0123456789abcdef

helm template tracking-baseline kubernetes/tracking-baseline \
  --set awsRegion=us-east-1 \
  --set backendSecretArn=arn:aws:secretsmanager:us-east-1:111122223333:secret:tracking-test/backend/runtime-AbCdEf \
  --set targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:111122223333:targetgroup/tracking-test-api/0123456789abcdef \
  | kubectl apply --dry-run=client --validate=false -f -

git diff --check
```

## Aplicação futura — não executada nesta entrega

> Este procedimento é apenas a referência operacional futura. Nenhum `terraform plan` remoto, `terraform apply`, comando contra EKS ou preenchimento de segredo foi executado nesta entrega.

Depois de revisão, aprovação e configuração do backend remoto do ambiente, o fluxo futuro será:

1. gerar e revisar o plano Terraform com o `.tfvars` do ambiente;
2. executar `terraform apply` somente com autorização explícita;
3. preencher o segredo indicado por `backend_runtime_secret_arn` por um canal que não exponha valores;
4. confirmar AWS Load Balancer Controller, Pod Identity Agent, ASCP e Metrics Server;
5. confirmar a baseline com réplicas zero e todos os nomes do contrato;
6. publicar uma imagem por digest em um processo separado;
7. invocar a action do backend para criar o ConfigMap, atualizar imagem, aplicar HPA e verificar rollout.

O chart Helm é aplicado pelo mesmo Terraform após o cluster e os add-ons. A remoção ou alteração da baseline também deve passar pelo plano da infraestrutura; a action do backend não corrige drift de probes, recursos, segurança, volumes, Service ou `TargetGroupBinding`.
# Rollout de observabilidade

Faça merge e aplique esta infraestrutura antes de publicar o backend com OTel. O
primeiro apply pode exigir importar o add-on ou log group já existente para o state;
esta PR não executa `terraform apply`. Após aplicar, publique o backend com o Helm
value `environment` correspondente (`dev`, `hml` ou `prod`).

Como validação pós-deploy, aguarde alguns minutos, confirme API e worker no CloudWatch
Application Signals, consulte `bullmq.backlog` no Logs Insights e confira os três
alarmes em CloudWatch. Alarmes sem eventos devem permanecer `OK`, pois ausência é
tratada como `notBreaching`.
