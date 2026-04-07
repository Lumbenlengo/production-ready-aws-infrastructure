# Service Level Objectives (SLOs)

**Service:** api.patriciolumbe.com
**Last updated:** 2025-03-01

---

## SLO 1 — Availability

| Attribute | Value |
|---|---|
| **Target** | 99.9% uptime |
| **Measurement** | ALB `UnHealthyHostCount == 0` |
| **Window** | Rolling 30 days |
| **Error budget** | 43.8 minutes downtime per month |

**Alert:** CloudWatch alarm `lumbenlengo-unhealthy-hosts` fires when any target is unhealthy.

---

## SLO 2 — Latency

| Attribute | Value |
|---|---|
| **Target** | p95 < 300ms |
| **Measurement** | ALB `TargetResponseTime` p95 |
| **Window** | Per deploy |
| **Error budget** | Tracked per deployment via CloudWatch dashboard |

**Alert:** CloudWatch alarm `lumbenlengo-high-latency` fires when p95 > 300ms for 2 consecutive 5-minute periods.

---

## SLO 3 — Error Rate

| Attribute | Value |
|---|---|
| **Target** | < 0.1% HTTP 5XX errors |
| **Measurement** | `HTTPCode_Target_5XX_Count / RequestCount` |
| **Window** | Rolling 1 hour |
| **Error budget** | < 1 in 1000 requests |

**Enforcement:** The `slo-checker` Lambda runs every 5 minutes. When the error rate exceeds 0.1%,
it sets the SSM parameter `/{project}/{env}/slo/deployment-gate` to `LOCKED`.
CodePipeline reads this gate before deploying — a locked gate blocks new deployments automatically.

---

## SLO 4 — Deploy Success Rate

| Attribute | Value |
|---|---|
| **Target** | 100% successful deployments to prod |
| **Measurement** | CodeDeploy deployment success |
| **Error budget** | Zero failed deploys to production |

**Enforcement:** CodeDeploy auto-rollback is enabled on `DEPLOYMENT_FAILURE` and
`DEPLOYMENT_STOP_ON_ALARM`. The high-cpu, high-error-rate, and unhealthy-hosts alarms
are configured as rollback triggers.

---

## Error Budget Runbook

When `/{project}/{env}/slo/deployment-gate` is `LOCKED`:

1. Check CloudWatch dashboard for the failing metric
2. Review recent CloudDeploy deployments for correlation
3. Fix the root cause (bad deploy, upstream dependency, capacity)
4. Manually reset the gate: `aws ssm put-parameter --name /lumbenlengo/dev/slo/deployment-gate --value OPEN --overwrite`
5. Verify the SLO checker sets it back to OPEN on the next run (within 5 minutes)
