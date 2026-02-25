# Kubernetes

Kubernetes is the control plane for running, scaling, and updating containerized workloads reliably.

This section focuses on practical operations: how resources behave, how rollouts happen, and how to debug failures quickly.

---

## Scope

The Kubernetes layer covers:

- Core workload resources and lifecycle
- Declarative updates and rollout safety
- Service discovery and networking basics
- Storage and configuration patterns
- High-signal debugging workflows

---

## Mental Model

Most Kubernetes incidents can be traced to one of these categories:

1. Desired state is wrong (manifest/config issue)
2. Scheduler cannot place Pods (resources, constraints, taints)
3. Runtime cannot start containers (image, command, permissions)
4. Network path is broken (Service, DNS, policy)
5. Readiness/health gates block traffic
6. Dependencies are unavailable (database, API, storage)

---

## Sections

### Deployments

Understand:

- How rolling updates and rollbacks work
- How ReplicaSets and Pods map to rollout state
- How to scale and restart safely
- How to diagnose stalled rollouts quickly

---

### DaemonSets

Understand:

- How to run one Pod per eligible node
- How update strategy affects node-agent rollouts
- How to verify node coverage and placement
- How to debug scheduling and rollout failures quickly

---

### Authentication and Authorization

Understand:

- How API requests are authenticated and authorized
- How to validate effective permissions with `kubectl auth can-i`
- How to apply least-privilege RBAC with Roles and Bindings
- How to troubleshoot `401 Unauthorized` vs `403 Forbidden` quickly

---

## Guiding Principle

When debugging Kubernetes:

- Start with desired vs actual state.
- Follow the object chain: Deployment -> ReplicaSet -> Pod -> Container.
- Use events and conditions before assumptions.

This keeps diagnosis fast and repeatable.
