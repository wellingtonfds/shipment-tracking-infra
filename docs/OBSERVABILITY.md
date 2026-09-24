# Observabilidade CloudWatch

## Coleta e retenção

O add-on EKS `amazon-cloudwatch-observability` coleta `stdout` JSON dos pods API e
worker no log group `/aws/containerinsights/<cluster>/application`. A retenção é
declarada por ambiente: `dev` 7 dias, `hml` 30 dias e `prod` 90 dias. O role dos nós
recebe `CloudWatchAgentServerPolicy` e `AWSXRayDaemonWriteAccess`; portanto essas
permissões alcançam os pods agendados nesses nós.

As anotações `instrumentation.opentelemetry.io/inject-nodejs: "true"` habilitam a
integração do add-on. O backend inicializa OTel em ESM antes do Nest e exporta somente
ao collector interno injetado; não existe endpoint público de métricas.

## Métricas e alarmes

Filtros JSON criam métricas em `ShipmentTracking/Observability`, com dimensões de
baixa cardinalidade: `Environment`, `Service` e, para backlog, `Queue`.

- `CircuitBreakerOpened`: `geocoder.circuit.opened`; alarme se soma >= 1 em 5 min.
- `BullMQBacklog`: valor de `bullmq.backlog`; alarmes distintos para `tracking-events`
  e `tracking-events-dlq` se máximo >= 500 em 10 min.

Todos os alarmes têm `actions_enabled = false` e `treat_missing_data = notBreaching`.
Não adicione request IDs, traces, shipment IDs ou usuários como dimensões.

## Consultas e diagnóstico

No CloudWatch Logs Insights, selecione o log group acima:

```text
fields @timestamp, event, queue, backlog, traceId, spanId
| filter event = "bullmq.backlog"
| stats max(backlog) by queue, bin(10m)
```

```text
fields @timestamp, providerKey, cooldownMs, traceId
| filter event = "geocoder.circuit.opened"
| sort @timestamp desc
```

Ao disparar backlog, diferencie `waiting`, `delayed` e `failed`, valide a saúde de
Redis e workers e só então altere escala. Ao abrir circuito, valide o provedor e o
cooldown. Use `traceId` para ligar o log ao Application Signals.
