# Cost and FinOps

> Figures are rough estimates for `ap-south-1` and change over time. Check the
> [AWS Pricing Calculator](https://calculator.aws/) before you deploy.

## What costs money while the stack is running

| Resource | Notes |
|----------|-------|
| EKS control plane | Fixed hourly fee per cluster (standard support) |
| NAT gateway | Hourly fee plus per-GB data processing |
| EC2 nodes (2x Spot, large) | Spot is usually a large discount versus On-Demand |
| RDS db.t4g.micro | Smallest Graviton instance, 20 GB gp3 |
| Application Load Balancer | Hourly fee plus LCUs |
| Public IPv4 addresses | NAT and ALB addresses are billed hourly |
| CloudWatch Logs | Control-plane, VPC flow and RDS logs, 7-day retention |

Expect very roughly **USD 0.25 to 0.40 per hour** with the defaults. Deploy,
explore, capture screenshots, then run `make destroy`. Leaving it running for a
month costs far more than the project is worth.

## Cost controls built in

- **Cost-allocation tags** on every resource through provider `default_tags`
  (`Project`, `Environment`, `Owner`, `CostCenter`). Activate them under
  *Billing > Cost allocation tags* to group spend in Cost Explorer.
- **AWS Budget** with forecast (80%) and actual (100%) email alerts, enabled
  when `budget_alert_email` is set.
- **Spot capacity** for nodes, diversified across four instance types.
- **Single NAT gateway** in dev.
- **EKS upgrade policy `STANDARD`**: the cluster upgrades at the end of
  standard support instead of silently moving to the much more expensive
  extended-support tier.
- **Right-sized requests/limits** for every workload, and HPA scaling on CPU so
  capacity follows demand.
- **ECR lifecycle policy** keeps the 20 newest images and expires untagged ones.
- **Short log retention** (7 days) and a 90-day expiry on old state versions.

## Ideas for further savings

- Karpenter for faster, bin-packed, Spot-aware node provisioning.
- VPC endpoints for ECR and S3 to reduce NAT data-processing charges.
- Graviton (arm64) nodes with a multi-architecture image.
- Scheduled scale-to-zero of the node group outside working hours.
