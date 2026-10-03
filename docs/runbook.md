# Runbook

Alerts defined in `helm/demo-app/templates/prometheusrule.yaml` link here.
Open Grafana with `make grafana-ui` (dashboard: **Demo App - Golden Signals**)
and Alertmanager with
`kubectl -n monitoring port-forward svc/kube-prometheus-stack-alertmanager 9093`.

## DemoAppDown

**Meaning:** Prometheus has no healthy scrape target for the app.

1. `kubectl -n demo get pods,deploy,endpoints`
2. Pods missing or pending: `kubectl -n demo describe pod <pod>` and check events
   (image pull errors, insufficient CPU/memory, Spot node reclaimed).
3. Pods running but not ready: `kubectl -n demo logs <pod>` and check `/readyz`
   (usually database connectivity, see below).
4. Check the Argo CD app: `kubectl -n argocd get application demo-app`.

## DemoAppHighErrorRate

**Meaning:** more than 5% of requests return 5xx for 5 minutes.

1. Grafana: which status codes and when did it start? Does it line up with a
   deploy? (`git log helm/demo-app/values-dev.yaml`)
2. `kubectl -n demo logs -l app.kubernetes.io/name=demo-app --since=15m`
3. If a deploy caused it, roll back with `git revert <commit>` and push.
   Argo CD redeploys the previous image.

## DemoAppHighLatencyP95

**Meaning:** p95 latency above 500 ms for 10 minutes.

1. Check CPU throttling and HPA status: `kubectl -n demo get hpa`,
   `kubectl -n demo top pods`.
2. HPA at `maxReplicas`: raise the limit or investigate the hot path.
3. Check RDS CPU and connections in CloudWatch.

## DemoAppContainerOOMKilled

**Meaning:** a container exceeded its memory limit and was killed.

1. `kubectl -n demo describe pod <pod>` and look for `Last State: Terminated, Reason: OOMKilled`.
2. Grafana memory panel: compare working set with the limit in `values.yaml`.
3. Raise `resources.limits.memory` (and requests) in Git; never patch the live
   Deployment, because Argo CD self-heal will revert it.
4. See [Game Day 01](rca/game-day-01-oomkilled.md) for a worked example.

## Database connectivity

1. Is the Kubernetes Secret present? `kubectl -n demo get externalsecret,secret`
2. ExternalSecret not `SecretSynced`: `kubectl -n demo describe externalsecret demo-app-db`
   (usually the Pod Identity association or secret name).
3. Network: the RDS security group must allow 5432 from the node security group.
4. Test from inside the cluster:
   `kubectl -n demo run pg --rm -it --image=postgres:17 --restart=Never -- psql "host=<endpoint> user=appadmin dbname=appdb sslmode=require"`
