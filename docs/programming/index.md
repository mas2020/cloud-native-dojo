# Programming

Modern platform engineering and DevOps work increasingly involves writing and maintaining code — automation scripts, CLI tools, operators, and infrastructure tooling.

This section covers programming languages and toolchains commonly used in cloud-native environments, with a focus on installation, setup, and operational use.

---

## Scope

The Programming section covers:

- Language installation and version management
- Toolchain setup on Linux
- Build and dependency workflows
- Environment reproducibility

---

## Languages

### Go

Go is the primary language of the cloud-native ecosystem.

Kubernetes, Docker, Terraform, Helm, and most cloud-native tooling are written in Go.

For platform engineers, knowing Go means you can:

- Read and understand upstream tooling source
- Write Kubernetes operators and controllers
- Build custom CLI tools and automation
- Contribute to the ecosystem

---

## Guiding Principle

Toolchains should be:

- Pinned to a specific version
- Reproducible across machines
- Easy to upgrade without breaking system state

Avoid relying on package manager versions for languages — they are frequently outdated and inconsistently maintained across distributions.
