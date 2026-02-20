# Deployments

Deployments are the core Kubernetes workload for running and updating stateless applications safely.

They provide controlled rollouts, rollback history, scaling, and declarative reconciliation between desired and actual state.

---

## What It Is

A Deployment manages a set of Pods (through ReplicaSets) and continuously works to match the declared specification.

In practice, Deployments give you:

- Declarative updates for Pods and ReplicaSets
- Rolling updates with controlled surge/unavailable behavior
- Rollback to prior revisions
- Consistent scaling operations
- Status conditions for rollout health (`Progressing`, `Available`)

Deployment basics that matter operationally:

- Use `apiVersion: apps/v1`
- Ensure `.spec.selector` matches pod template labels
- Treat selector design as stable from day one (in `apps/v1`, selector changes are constrained and risky)

---

## When to Use It

Use a Deployment when:

- Your app is stateless (or state-externalized) and horizontally scalable
- You need safe version rollouts and rollback capability
- You want GitOps/IaC-friendly, declarative workload management
- You need repeatable scaling and rollout diagnostics

Do not use Deployments for stateful identity/storage guarantees; use StatefulSets for those cases.

---

## Core Commands

### Create or Apply a Deployment

From manifest (recommended):

```bash
kubectl apply -f deployment.yaml
```

Quick scaffold:

```bash
kubectl create deployment web --image=nginx:1.27
```

Dry-run validation before apply:

```bash
kubectl apply --dry-run=server -f deployment.yaml
```

Why it matters:

- Keeps rollouts repeatable and reviewable
- Server-side dry run catches schema/validation issues early

### Baseline Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  labels:
    app: web
spec:
  replicas: 3
  revisionHistoryLimit: 10
  minReadySeconds: 5
  progressDeadlineSeconds: 600
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: ghcr.io/example/web:1.0.0
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
```

Why it matters:

- `progressDeadlineSeconds` helps detect stalled rollouts
- Readiness probes protect users during rolling updates
- `revisionHistoryLimit` controls rollback history retention

### Inspect Current State

```bash
kubectl get deployments
kubectl get deployment web -o wide
kubectl describe deployment web
kubectl get rs -l app=web
kubectl get pods -l app=web -o wide
```

Why it matters:

- Shows desired/updated/available counts quickly
- Links Deployment behavior to underlying ReplicaSets and Pods

### Watch Rollout Progress

```bash
kubectl rollout status deployment/web
kubectl rollout status deployment/web --timeout=2m
```

Why it matters:

- Standard operational check for update completion
- Useful in CI/CD to gate promotion steps

### Update Image Safely

```bash
kubectl set image deployment/web web=ghcr.io/example/web:1.1.0
kubectl rollout status deployment/web
```

Why it matters:

- Triggers a new revision via pod template change
- Clear path to immediate verification after update

### Rollback and History

```bash
kubectl rollout history deployment/web
kubectl rollout undo deployment/web
kubectl rollout undo deployment/web --to-revision=3
```

Why it matters:

- Fast recovery path when a rollout is unhealthy
- History visibility improves incident response speed

### Pause and Resume Rollouts

```bash
kubectl rollout pause deployment/web
kubectl set image deployment/web web=ghcr.io/example/web:1.2.0
kubectl rollout resume deployment/web
```

Why it matters:

- Lets you batch multiple template changes before rollout starts
- Reduces churn from multiple partial rollouts

### Scale and Autoscale

Manual scale (immediate, operator-driven):

```bash
kubectl scale deployment/web --replicas=6
kubectl get deployment web
```

Autoscale with HPA (continuous, metric-driven):

```bash
kubectl autoscale deployment/web --min=3 --max=12 --cpu-percent=70
kubectl get hpa
kubectl describe hpa web
```

Why it matters:

- `kubectl scale` is best for short-term or incident response changes
- HPA continuously adjusts replicas based on observed metrics

Important behavior:

- If HPA is enabled, it controls the Deployment replica count and can overwrite manual `kubectl scale` values.
- For CPU-based HPA, set CPU requests on containers and ensure cluster metrics are available (for example via Metrics Server).

### Restart Pods Without Spec Drift

```bash
kubectl rollout restart deployment/web
kubectl rollout status deployment/web
```

Why it matters:

- Useful for config reloads/secrets refresh scenarios
- Keeps rollout tracked in Deployment history

### High-Signal Troubleshooting Commands

```bash
kubectl describe deployment web
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe rs -l app=web
kubectl describe pod -l app=web
kubectl logs -l app=web --tail=200
```

Why it matters:

- Surfaces probe failures, image pull errors, quota issues, and scheduling constraints
- Connects symptoms to specific object-level events

---

## Real-World Example

Scenario: rolling out `web:1.1.0` causes readiness failures and degraded availability.

1. Apply image update:

```bash
kubectl set image deployment/web web=ghcr.io/example/web:1.1.0
```

2. Watch rollout:

```bash
kubectl rollout status deployment/web --timeout=2m
```

3. Rollout stalls; inspect:

```bash
kubectl describe deployment web
kubectl get rs -l app=web
kubectl describe pod -l app=web
kubectl logs -l app=web --tail=200
```

4. Confirm failing readiness path in app startup output.

5. Immediate recovery:

```bash
kubectl rollout undo deployment/web
kubectl rollout status deployment/web
```

6. Fix image/config and deploy next version once healthy.

Result:

- Users recover quickly with rollback
- Deployment history retains traceability for post-incident review

---

## Debugging Pattern

Use this flow for Deployment incidents:

1. Check desired vs available (`kubectl get deployment`)
2. Check rollout state (`kubectl rollout status`)
3. Inspect Deployment conditions/events (`kubectl describe deployment`)
4. Inspect ReplicaSet transitions (`kubectl get rs`, `kubectl describe rs`)
5. Inspect Pod-level failures (`kubectl describe pod`, `kubectl logs`)
6. Decide: wait, rollback, or patch
7. Re-run rollout status until stable

Diagnostic shortcuts:

- `ProgressDeadlineExceeded`: rollout is stalled; inspect probes, pull errors, quota, scheduling
- Pods `ImagePullBackOff`: image/tag/auth issue, not Deployment logic
- Pods `CrashLoopBackOff`: app/runtime issue; Deployment is only surfacing the failure
- Desired replicas present but unavailable remains high: readiness gate is blocking promotion

---

## Common Pitfalls

- Using mutable tags like `:latest` in production rollouts
- Forgetting readiness probes and causing user-facing errors during rollout
- Manually editing live objects repeatedly instead of managing manifests in Git
- Changing selectors after creation and orphaning old ReplicaSets/Pods
- Assuming scaling creates a new revision (it does not)
- Keeping no rollback history (`revisionHistoryLimit` too small)
- Skipping rollout status checks in CI/CD
