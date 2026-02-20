# Cloud Native Field Guide

Practical command and operations reference for modern cloud-native environments.

This project is an opinionated, production-oriented guide covering:

- Linux foundations
- Containers
- Kubernetes
- Databases
- GitOps
- Infrastructure as Code
- Real-world troubleshooting patterns

It is not a replacement for official documentation.  
It is a distilled operational reference for daily work.

---

## Philosophy

Cloud native is layered.

Understanding Kubernetes without understanding Linux leads to fragile systems.
Understanding containers without understanding networking leads to blind debugging.

This guide follows a layered mental model:

1. Foundations (Linux, networking, debugging)
2. Containers
3. Kubernetes
4. Databases
5. Packaging and GitOps
6. Infrastructure
7. Troubleshooting scenarios

Each section prioritizes:

- High-signal commands
- Real-world usage
- Diagnostic flows
- Common failure patterns

---

## Structure Overview

### Foundations

Core Linux knowledge required for cloud-native operations:

- Filesystem navigation and manipulation
- Process inspection
- Networking diagnostics
- Log inspection
- Text processing
- Debugging techniques

---

### Containers

Operational reference for:

- Docker CLI
- Image management
- Volumes
- Container networking
- Runtime troubleshooting

---

### Kubernetes

Production-focused reference including:

- kubectl commands
- Core resources
- Deployments
- Services and networking
- Storage
- Configuration
- Debugging workflows

---

### Databases

Operational reference for:

- PostgreSQL in Docker
- Connection and authentication checks
- Backup and restore commands
- Initialization and data persistence behavior

---

### Local Clusters

Local development and testing with:

- kind
- Minikube

---

### Packaging

Application lifecycle management:

- Helm
- Kustomize

---

### GitOps & CI/CD

Continuous delivery and Git-based operations:

- GitHub Actions
- Argo CD

---

### Infrastructure

Infrastructure provisioning and lifecycle management:

- Terraform

---

### Troubleshooting Scenarios

Scenario-driven operational playbooks:

- Container not starting
- Pod CrashLoopBackOff
- Service not reachable
- High CPU or memory usage

These sections focus on diagnostic thinking, not just commands.

---

## How to Use This Guide

You can:

- Browse by technology
- Follow the layered model
- Use search to find specific commands
- Use troubleshooting scenarios for incident handling

Each page follows a consistent structure:

- What it is
- When to use it
- Core commands
- Real-world example
- Debugging pattern
- Common pitfalls

---

## Target Audience

- Platform engineers
- DevOps engineers
- SREs
- Backend engineers working with Kubernetes
- Engineers transitioning into cloud-native roles

---

## Contributing

Contributions are welcome.

Improvements should prioritize:

- Clarity
- Practicality
- Real-world examples
- Concise explanations

Before submitting a PR:

- Follow the existing page structure
- Avoid duplicating official documentation
- Prefer operational insight over theory

See `CONTRIBUTING.md` for details.

---

## Long-Term Vision

The goal is to evolve this project into:

- A high-signal operational reference
- A community-driven cloud-native handbook
- A practical companion to official documentation
- A curated body of production knowledge

Cloud-native systems are complex.

Clarity is leverage.
