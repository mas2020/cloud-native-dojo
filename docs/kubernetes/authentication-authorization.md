# Authentication and Authorization

In Kubernetes, every API request is evaluated through access control stages before it is accepted.

For day-to-day operations, understanding Authentication and Authorization is mandatory for secure troubleshooting and platform reliability.

---

## What It Is

Kubernetes API access control follows this order:

1. Authentication: who is making the request?
2. Authorization: is this identity allowed to do this action?
3. Admission: should the request be modified or rejected before persistence?

Authentication and Authorization are related but distinct:

- Authentication identifies the caller (user, group, service account)
- Authorization decides what that identity can do (verbs, resources, namespaces, non-resource URLs)

Important fundamentals:

- Kubernetes has no native "User" object for normal users
- Normal users are managed externally (OIDC, certificates, proxies, webhooks, etc.)
- Service accounts are Kubernetes-native identities for workloads
- Authorization is deny-by-default unless explicitly allowed

---

## When to Use It

Use this guide when:

- A request fails with `Unauthorized` (`401`) or `Forbidden` (`403`)
- A service account cannot access required resources
- You need least-privilege RBAC for workloads or teams
- You need to validate permissions before rollout
- You are migrating or reviewing auth/authz control-plane configuration

---

## Core Commands

### Verify Current Identity

```bash
kubectl config current-context
kubectl config view --minify
kubectl auth whoami
kubectl auth whoami -o json
```

Why it matters:

- Confirms which user/service-account attributes are currently in effect
- Prevents debugging the wrong context or wrong identity

### Check Effective Permissions Quickly

```bash
kubectl auth can-i create pods -n dev
kubectl auth can-i list deployments.apps -n prod
kubectl auth can-i get /healthz
kubectl auth can-i --list -n dev
```

With impersonation (great for validation):

```bash
kubectl auth can-i list pods --as=system:serviceaccount:dev:app-sa -n dev
```

Why it matters:

- Fastest practical check for authorization behavior
- Uses server-side review APIs and works across authorization modes

### Create Namespace-Scoped RBAC (Role + RoleBinding)

```bash
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding app-read-pods \
  --role=pod-reader \
  --serviceaccount=dev:app-sa \
  -n dev
```

Why it matters:

- Enforces least privilege in a single namespace
- Standard pattern for most application service accounts

### Create Cluster-Scoped RBAC (ClusterRole + ClusterRoleBinding)

```bash
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding app-read-nodes \
  --clusterrole=node-reader \
  --serviceaccount=dev:app-sa
```

Why it matters:

- Needed for cluster-wide resources
- Must be used carefully to avoid privilege overreach

### Inspect RBAC Objects and Subjects

```bash
kubectl get role,rolebinding -n dev
kubectl get clusterrole,clusterrolebinding
kubectl describe rolebinding app-read-pods -n dev
kubectl describe clusterrolebinding app-read-nodes
```

Why it matters:

- Reveals subject/role mismatches quickly
- Shows exactly what is bound to whom

### Service Account Identity and Tokens

```bash
kubectl get sa -n dev
kubectl describe sa app-sa -n dev
kubectl create token app-sa -n dev
```

Why it matters:

- Validates workload identity wiring
- `kubectl create token` uses modern token flows instead of relying on legacy static secret tokens

### Validate Access Using Review APIs (Explicit)

```yaml
apiVersion: authorization.k8s.io/v1
kind: SelfSubjectAccessReview
spec:
  resourceAttributes:
    group: apps
    resource: deployments
    verb: create
    namespace: dev
```

Apply:

```bash
kubectl create -f selfsubjectaccessreview.yaml -o yaml
```

Why it matters:

- Gives explicit allow/deny result from the API server
- Useful in automation and policy diagnostics

### Control-Plane Configuration (Cluster Admin Context)

Authentication configuration:

- `--authentication-config` with `AuthenticationConfiguration` (`apiserver.config.k8s.io/v1`)

Authorization configuration:

- `--authorization-config` with `AuthorizationConfiguration` (`apiserver.config.k8s.io/v1`)

Why it matters:

- Structured config is the modern path for advanced authn/authz configuration
- Avoids drift and improves auditability compared to scattered flags

---

## Real-World Example

Scenario: an app in namespace `dev` fails with `403 Forbidden` when listing Pods.

1. Confirm caller identity:

```bash
kubectl auth whoami
kubectl get pod app-xyz -n dev -o yaml | rg serviceAccountName
```

2. Confirm effective access for the workload identity:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:dev:app-sa -n dev
```

3. Inspect bindings:

```bash
kubectl get rolebinding -n dev
kubectl describe rolebinding app-read-pods -n dev
```

4. Fix RBAC scope mismatch (for example binding in wrong namespace), then re-check:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:dev:app-sa -n dev
```

5. Validate app behavior and logs after access is allowed.

Likely outcomes:

- Missing RoleBinding
- Binding to wrong namespace/service account name
- Role verbs/resources incomplete for required API action

---

## Debugging Pattern

Use this sequence for access-control incidents:

1. Identify status code first: `401` vs `403`
2. Confirm identity (`kubectl auth whoami`, service account on PodSpec)
3. Test permissions (`kubectl auth can-i ...`)
4. Inspect Role/ClusterRole and bindings
5. Verify namespace scope and subject strings exactly
6. Re-test with impersonation and minimal required verb/resource

Diagnostic shortcuts:

- `401 Unauthorized`: authentication failure (bad/expired/missing credentials)
- `403 Forbidden`: authenticated identity lacks permission
- Works with your user but fails in Pod: service account RBAC mismatch
- Intermittent failures: token expiration/rotation or admission/policy side effects

---

## Common Pitfalls

- Treating authentication and authorization as the same problem
- Granting `cluster-admin` instead of creating least-privilege roles
- Forgetting namespace scope on Roles/RoleBindings
- Mis-typing service account subjects (`system:serviceaccount:<ns>:<name>`)
- Assuming role exists means access exists (binding is what grants access)
- Using legacy, long-lived service account token secret patterns by default
- Ignoring impersonation checks before applying production RBAC changes
