# Game Day 01: demo-app OOMKilled after a memory limit change

> **How to use this document.** This is a controlled failure exercise
> ("game day"). Follow the steps in *Reproduce*, observe what actually
> happens, and replace every `TODO` with your real observations, timestamps
> and screenshots. Do not publish numbers you did not measure.

| Field | Value |
|-------|-------|
| Date | TODO |
| Environment | dev |
| Severity | SEV-3 (simulated) |
| Duration | TODO (from bad commit to recovery) |
| Author | TODO |

## Summary

A Git change lowered the demo-app container memory limit below the
application's normal working set. New pods were OOMKilled repeatedly and
entered `CrashLoopBackOff`. The rolling-update strategy (`maxUnavailable: 0`)
kept the old pods serving traffic, so user impact was TODO. The change was
reverted in Git and Argo CD rolled back automatically.

## Reproduce

1. Note the normal memory working set in Grafana (*Pod memory working set*).
   Observed: TODO MiB.
2. In `helm/demo-app/values.yaml`, set `resources.limits.memory: 40Mi` and
   `resources.requests.memory: 40Mi`, then commit and push to `main`.
3. Watch the rollout:
   `kubectl -n demo get pods -w` and `kubectl -n argocd get application demo-app`.
4. Note when `DemoAppContainerOOMKilled` fires in Alertmanager.
5. Revert: `git revert <commit> && git push`. Watch Argo CD restore healthy pods.

## Timeline

| Time (IST) | Event |
|------------|-------|
| TODO | Bad commit pushed |
| TODO | Argo CD synced; new ReplicaSet created |
| TODO | First OOMKilled container (`kubectl describe pod`) |
| TODO | `DemoAppContainerOOMKilled` alert fired |
| TODO | Root cause identified |
| TODO | Revert pushed |
| TODO | All pods Ready; alert resolved |

## Detection

- Alert: `DemoAppContainerOOMKilled` (Prometheus rule, `kube-state-metrics`).
- Signals: `Last State: Terminated, Reason: OOMKilled, Exit Code: 137` in
  `kubectl describe pod`; restart count climbing on the Grafana dashboard.
- Time to detect: TODO.

## Root cause

The memory limit (40Mi) was lower than the process's steady-state working set
(TODO MiB measured). The kernel OOM killer terminated the container as soon as
usage crossed the cgroup limit.

## Why impact was limited

- `maxUnavailable: 0` meant old pods were not removed until new pods became
  Ready, and the new pods never became Ready.
- The PodDisruptionBudget kept at least one pod available.
- Readiness probes stopped broken pods from receiving traffic.

## Resolution

Reverted the commit in Git. Argo CD synced the previous values and the
Deployment returned to healthy pods. Time to recover: TODO.

## Action items

| Action | Type | Status |
|--------|------|--------|
| Keep the OOMKilled alert and runbook entry | Detect | Done |
| Add a CI check that rejects memory limits below a minimum | Prevent | TODO |
| Document memory baseline in `values.yaml` comments | Prevent | TODO |
| Consider Argo Rollouts with automated analysis to abort bad rollouts | Mitigate | TODO |

## Lessons learned

TODO: write two or three sentences in your own words about what you observed.
