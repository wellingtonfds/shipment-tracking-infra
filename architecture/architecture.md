# Arquitetura

```mermaid
flowchart TB
  Internet --> DNS[Route 53]
  DNS --> WAF[AWS WAF]
  WAF --> ALB[ALB HTTPS]
  ALB --> TG[Target group IP]

  subgraph VPC[VPC em duas zonas de disponibilidade]
    subgraph A[Zona A]
      PodA[Pod EKS]
      RedisA[Redis primário]
    end
    subgraph B[Zona B]
      PodB[Pod EKS]
      RedisB[Redis réplica]
    end
    TG --> PodA
    TG --> PodB
    PodA --> DB[(RDS SQL Server Multi-AZ)]
    PodB --> DB
    PodA --> RedisA
    PodB --> RedisB
  end

  Pipeline[Pipeline do backend] --> ECR[ECR com scan]
  ECR --> PodA
  ECR --> PodB
  Secrets[Secrets Manager e KMS] --> PodA
  Secrets --> PodB
```

## Fronteiras e disponibilidade

O banco e o cache permanecem em sub-redes isoladas, sem acesso público. O RDS usa failover Multi-AZ e senha mestre gerenciada pelo RDS; Redis é um cache com réplica e failover, não uma fonte de verdade. O ALB, EKS, NAT e Redis são distribuídos entre duas zonas.

O fluxo de entrega é: pipeline do backend publica uma imagem imutável no ECR; o deployment no EKS usa ao menos duas réplicas, HPA e `/health`; o `TargetGroupBinding` registra os pods saudáveis no target group do ALB.

## Mapa da configuração Terraform

A configuração é um único módulo raiz, dividido por domínio. `provider.tf` fornece o contexto comum; `network.tf` fornece a VPC; `security.tf` define criptografia e conectividade; `registry.tf`, `eks.tf`, `data.tf` e `edge.tf` fornecem os serviços de imagem, computação, dados e borda.

O bloco `module "vpc"` consome `terraform-aws-modules/vpc/aws`. O código baixado em `.terraform/modules/vpc` é somente cache de dependência local e não deve ser tratado como parte desta arquitetura nem enviado ao repositório.

Para visualizadores que recebem o conteúdo Mermaid diretamente, use [architecture.mmd](architecture.mmd). O arquivo não contém Markdown nem cercas de código.

