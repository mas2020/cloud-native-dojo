# DaemonSets

DaemonSets ensure a Pod runs on every eligible node (or on a targeted subset of nodes).

They are the standard Kubernetes pattern for node-level agents such as log shippers, metrics collectors, and CNI-related components.

---

## What It Is

A DaemonSet is a workload controller that maintains one Pod per eligible node.

As nodes are added or removed, the DaemonSet automatically adds or removes Pods to keep coverage aligned with cluster state.

Common use cases:

- Log collection agents (for example Fluent Bit / Fluentd)
- Node metrics agents
- Storage and networking node components
- Security/monitoring side agents

Operationally important behavior:

- DaemonSet Pods are node-scoped by design, not replica-count scoped
- Node eligibility is controlled by selectors, affinity, taints/tolerations, and scheduling rules
- Rolling updates are controlled by `.spec.updateStrategy`

---

## When to Use It

Use a DaemonSet when:

- You need one instance per node
- The workload provides node-local functionality
- Coverage across nodes matters more than arbitrary replica count

Do not use a DaemonSet for stateless frontends/backends where horizontal scaling by replica count is required; use a Deployment for those.

---

## Core Commands

Namespace note:

- The examples below assume the DaemonSet runs in `kube-system`.
- Add `-n kube-system` (as shown) when your current context namespace is different.

### Create or Update a DaemonSet

```bash
kubectl apply -f fluentd-ds.yaml -n kube-system
```

Why it matters:

- Declarative apply is repeatable and GitOps-friendly
- Any `.spec.template` change triggers rollout behavior according to update strategy

### Minimal DaemonSet Manifest

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-agent
  namespace: kube-system
  labels:
    k8s-app: fluentd-agent
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-agent
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        k8s-app: fluentd-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd
        image: quay.io/fluentd_elasticsearch/fluentd:v5.0.1
```

Why it matters:

- `selector` must match template labels
- `RollingUpdate` is default and safest for gradual node-by-node changes
- `maxUnavailable` controls rollout disruption

### Inspect DaemonSets

```bash
kubectl get daemonsets
kubectl get ds -o wide
kubectl get ds fluentd-agent -n kube-system -o yaml
kubectl get ds fluentd-agent -n kube-system -o json
kubectl describe ds fluentd-agent -n kube-system
```

Why it matters:

- Shows desired/current/ready/available pod coverage per node set
- `describe` reveals events and rollout blockers

### Track Rollout and Revision History

```bash
kubectl rollout status ds/fluentd-agent -n kube-system
kubectl rollout history ds/fluentd-agent -n kube-system
kubectl rollout history ds/fluentd-agent --revision=1 -n kube-system
```

Why it matters:

- Confirms whether update is actually progressing
- Helps identify what changed between revisions

### Update Image and Record Change Cause

```bash
kubectl set image ds/fluentd-agent fluentd=quay.io/fluentd_elasticsearch/fluentd:v5.0.1 -n kube-system
kubectl annotate ds/fluentd-agent -n kube-system kubernetes.io/change-cause="bump fluentd image to v5.0.1" --overwrite
kubectl rollout status ds/fluentd-agent -n kube-system
```

Why it matters:

- `set image` is the fastest safe path for image-only updates
- Explicit change-cause annotation improves rollout history readability

### Roll Back a Bad Revision

```bash
kubectl rollout undo ds/fluentd-agent -n kube-system
kubectl rollout undo ds/fluentd-agent --to-revision=1 -n kube-system
kubectl rollout status ds/fluentd-agent -n kube-system
```

Why it matters:

- Shortens recovery time after bad image/config rollouts
- Allows controlled return to known-good revisions

### Validate Pod Placement and Coverage

```bash
kubectl get all -n kube-system -l k8s-app=fluentd-agent -o wide
kubectl get ds,po -n kube-system -l k8s-app=fluentd-agent
kubectl get nodes
```

Why it matters:

- Verifies expected one-per-node behavior across eligible nodes
- Quickly exposes missing Pods on specific nodes

### Delete DaemonSet

```bash
kubectl delete ds fluentd-agent -n kube-system
```

Why it matters:

- Cleans up DaemonSet-managed Pods
- Useful when replacing a node agent with a new selector/architecture

Note:

- `kubectl delete ds ... --cascade=orphan -n kube-system` leaves Pods behind (special-case operational usage)

---

## Real-World Example

Scenario: you roll out a new Fluentd image and logs stop arriving from some nodes.

1. Apply the updated manifest:

```bash
kubectl apply -f fluentd-ds.yaml -n kube-system
kubectl rollout status ds/fluentd-agent -n kube-system
```

2. Rollout stalls. Inspect state:

```bash
kubectl describe ds fluentd-agent -n kube-system
kubectl get ds,po -n kube-system -l k8s-app=fluentd-agent -o wide
kubectl get nodes
```

3. Identify nodes missing DaemonSet Pods, then inspect failing Pods:

```bash
kubectl get pods -n kube-system -l k8s-app=fluentd-agent -o wide
kubectl logs -l k8s-app=fluentd-agent --tail=200 -n kube-system
```

4. Root cause: new image tag was wrong for one architecture.

5. Recovery:

```bash
kubectl rollout undo ds/fluentd-agent -n kube-system
kubectl rollout status ds/fluentd-agent -n kube-system
```

Result:

- Node coverage returns
- Log pipeline stabilizes
- Revision history preserves incident traceability

---

## Debugging Pattern

Use this sequence for DaemonSet incidents:

1. Check desired/current/ready counts (`kubectl get ds`)
2. Check rollout progress (`kubectl rollout status ds/...`)
3. Inspect controller events (`kubectl describe ds ...`)
4. Compare node list vs pod placement (`kubectl get nodes`, `kubectl get pods -o wide`)
5. Inspect failing pod logs and events (`kubectl logs`, `kubectl describe pod`)
6. Decide: fix-forward or rollback (`kubectl rollout undo`)

Diagnostic shortcuts:

- Desired > Ready with `ImagePullBackOff`: image/tag/registry/auth issue
- Desired > Current on subset of nodes: scheduling/taints/resources issue
- Current = Desired but app still failing: runtime/config issue in container, not placement
- Rollout appears frozen: inspect update strategy and unavailable budget (`maxUnavailable` / `maxSurge`)

---

## Common Pitfalls

- Using DaemonSet when a Deployment is the correct model
- Forgetting control-plane tolerations when node agents must run there
- Mismatched selector and pod template labels
- Updating images without checking rollout status
- Assuming every node is eligible when node selectors/affinity/taints filter nodes
- Rolling out node-agent changes during peak load without controlling update disruption
- Relying on deprecated `--record` habits instead of explicit change annotations
