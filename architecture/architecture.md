# Arquitetura

```mermaid
flowchart TB
  Internet --> DNS[Route 53]
  DNS --> WAF[AWS WAF]
  WAF --> ALB[ALB HTTPS]
  ALB --> TG[Target group IP]
  subgraph VPC[VPC em duas zonas]
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
  ECR[ECR com scan] --> PodA
  ECR --> PodB
  Secrets[Secrets Manager e KMS] --> PodA
  Secrets --> PodB
```

O banco e o cache permanecem em sub-redes isoladas, sem acesso público. O RDS usa failover Multi-AZ e senha mestre gerenciada pelo RDS; Redis é um cache com réplica e failover, não uma fonte de verdade.

