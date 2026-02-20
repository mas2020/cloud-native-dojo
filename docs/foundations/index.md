# Foundations

Cloud-native systems ultimately run on Linux.

Before containers, before orchestration, before GitOps — there is the operating system, the network stack, and the process model.

This section focuses on the operational fundamentals required to debug and reason about distributed systems.

It is intentionally practical.

---

## Scope

The Foundations layer covers:

- Filesystem navigation and manipulation
- Process inspection and control
- Networking diagnostics
- Log inspection
- Text processing
- Debugging techniques

These skills are mandatory for:

- Container troubleshooting
- Kubernetes debugging
- Incident response
- Performance analysis

---

## Mental Model

Every cloud-native failure eventually maps to one of these domains:

1. Process not running
2. Port not listening
3. Network not reachable
4. File not found or permission denied
5. Resource exhaustion (CPU, memory, disk)
6. Configuration mismatch

Mastering Linux inspection tools drastically reduces debugging time.

---

## Sections

### Filesystem

Understand:

- Directory structure
- Permissions
- Ownership
- Disk usage
- File manipulation

---

### Processes

Understand:

- Process tree
- Signals
- CPU and memory consumption
- Background services

---

### Networking

Understand:

- IP addressing
- Routing
- Open ports
- Listening services
- Packet inspection

---

### Logs

Understand:

- System logs
- Application logs
- Journal-based logging
- Streaming logs

---

### Text Processing

Understand:

- Filtering output
- Pattern matching
- Transforming logs
- Extracting signals from noise

---

## Guiding Principle

When debugging:

- Observe first.
- Confirm assumptions.
- Isolate layers.
- Avoid guessing.

The tools in this section are your primary instruments.