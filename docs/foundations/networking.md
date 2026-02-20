# Networking

Networking failures are among the most common issues in cloud-native systems.

Before debugging Kubernetes Services, Ingress, or service mesh traffic, you need strong Linux networking fundamentals.

This page gives you a practical command set for diagnosing reachability, DNS, ports, routing, and packet flow.

---

## What It Is

Linux networking diagnostics are the tools and checks you use to answer:

- Does this host or container have an IP?
- Is the route to the destination valid?
- Is DNS returning the expected result?
- Is the target port listening?
- Are packets reaching the destination and returning?

In practice, networking debugging is layer-by-layer elimination:

1. Link/interface layer (is the interface up?)
2. IP/routing layer (can packets be routed?)
3. Name resolution layer (does DNS resolve correctly?)
4. Transport layer (is TCP/UDP port open?)
5. Application layer (does HTTP/gRPC/etc. return expected responses?)

---

## When to Use It

Use these commands when:

- A service is unreachable
- A pod/container cannot connect to a dependency
- DNS resolution fails or returns unexpected addresses
- Traffic times out intermittently
- Latency spikes or packet loss appear
- A port is reported as "closed" or "connection refused"

---

## Core Commands

### `ip` (interfaces, addresses, routes)

Inspect interface state and IP assignment:

```bash
ip addr
ip -br addr
ip link
```

Inspect route selection and default gateway:

```bash
ip route
ip route get 10.96.0.10
```

Why it matters:

- `state DOWN` means interface-level issue
- Missing default route breaks external access
- Wrong route metric can send traffic through the wrong path

### `ss` (socket and listening port inspection)

Check listening sockets:

```bash
ss -lntp
ss -lunp
```

Check active outbound/inbound connections:

```bash
ss -tnp
ss -s
```

Why it matters:

- Confirms whether a process is actually listening on expected port
- Helps separate "app not listening" from "network blocked"

### `ping` (basic reachability and packet loss)

```bash
ping -c 4 8.8.8.8
ping -c 4 example.com
```

Why it matters:

- IP ping success + DNS ping failure suggests name resolution issue
- Loss/latency variance can indicate congestion or unstable links

Note:

- Some environments block ICMP; failed ping does not always mean service is down

### `traceroute` or `tracepath` (path visibility)

```bash
traceroute 1.1.1.1
tracepath 1.1.1.1
```

Why it matters:

- Shows where packets stop across hops
- Useful for identifying routing boundaries or upstream blocks

### `dig` / `nslookup` / `getent` (DNS checks)

Query DNS directly:

```bash
dig example.com
dig +short api.internal.example.com
dig @8.8.8.8 example.com
```

Resolve using system resolver path:

```bash
getent hosts example.com
cat /etc/resolv.conf
```

Why it matters:

- Distinguishes DNS server issues from local resolver configuration issues
- Makes split-horizon DNS mistakes obvious

### `curl` (application-layer validation)

Validate HTTP reachability with timing breakdown:

```bash
curl -v http://service:8080/health
curl -sS -o /dev/null -w "dns=%{time_namelookup} connect=%{time_connect} ttfb=%{time_starttransfer} total=%{time_total}\n" http://service:8080/health
```

Why it matters:

- Confirms whether the app responds correctly, not just whether port opens
- Timing fields quickly identify whether delay is DNS, TCP connect, or server response

### `nc` (raw TCP/UDP connectivity tests)

```bash
nc -vz db.internal 5432
nc -vz redis.internal 6379
```

Why it matters:

- Fast way to validate transport connectivity without full client tooling
- Useful for smoke-checking security group/firewall behavior

### `tcpdump` (packet-level inspection)

Capture traffic on interface:

```bash
sudo tcpdump -i eth0 host 10.10.2.15
sudo tcpdump -i any port 53
sudo tcpdump -i any tcp port 443
```

Why it matters:

- Definitive evidence of whether packets arrive/leave
- Essential for diagnosing NAT, DNS, and handshake failures

Tip:

- Save capture for deeper analysis:

```bash
sudo tcpdump -i any -w /tmp/capture.pcap host 10.10.2.15
```

### `iptables` / `nft` (firewall policy visibility)

On systems using iptables:

```bash
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
```

On systems using nftables:

```bash
sudo nft list ruleset
```

Why it matters:

- Identifies dropped traffic and NAT rules influencing packet flow
- Prevents misattributing policy blocks to application bugs

### Kubernetes-adjacent checks from foundations context

When debugging from a node or jump host, these commands are still useful:

```bash
kubectl get svc -A
kubectl get endpoints -A
kubectl exec -it <pod> -- sh
kubectl exec -it <pod> -- nslookup kubernetes.default.svc
kubectl exec -it <pod> -- nc -vz my-service 8080
```

Why it matters:

- Confirms whether issue is cluster DNS/service plumbing or app-level behavior

---

## Real-World Example

Scenario: `payments-api` cannot connect to `postgres` in a cluster-backed environment.

Step-by-step workflow:

1. Verify local DNS resolution from workload context:

```bash
kubectl exec -it payments-api-abc -- nslookup postgres.default.svc.cluster.local
```

2. Validate transport connectivity from same pod:

```bash
kubectl exec -it payments-api-abc -- nc -vz postgres.default.svc.cluster.local 5432
```

3. Check whether target process is listening on expected address/port:

```bash
ss -lntp | grep 5432
```

4. Confirm route to destination subnet:

```bash
ip route
ip route get <postgres-pod-ip>
```

5. If still failing, capture packets at destination node:

```bash
sudo tcpdump -i any host <postgres-pod-ip> and port 5432
```

Likely outcomes:

- DNS fails: CoreDNS or resolver config issue
- DNS works, `nc` fails: policy/firewall/routing issue
- TCP connects, app still fails: authentication/TLS/app configuration issue

---

## Debugging Pattern

Use this repeatable sequence:

1. Identify source and destination precisely (IP, hostname, port, protocol)
2. Test DNS resolution (`dig`, `getent`, `nslookup`)
3. Test transport reachability (`nc`, `ss`, `curl`)
4. Validate route and path (`ip route`, `traceroute`)
5. Inspect packet flow (`tcpdump`)
6. Inspect policy controls (`iptables`/`nft`, network policies, security groups)
7. Confirm application-level behavior (HTTP status, TLS handshake, auth)

Decision shortcuts:

- "Connection refused" usually means host reachable but nothing listening on port
- "No route to host" usually means routing or network segmentation issue
- "Name or service not known" usually means resolver or DNS record problem
- "Timed out" often points to drops by firewall/policy or asymmetric routing

---

## Common Pitfalls

- Debugging only from your laptop instead of from the failing workload context
- Assuming DNS success means service health; DNS only returns an address
- Ignoring IPv6 vs IPv4 mismatch in dual-stack environments
- Forgetting that ICMP may be blocked while TCP is allowed
- Confusing closed port with filtered port (`refused` vs `timed out`)
- Checking service object but not endpoints/backing pods
- Relying on one tool; always validate across layers
