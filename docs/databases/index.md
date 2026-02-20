# Databases

Cloud-native applications are only as reliable as the data systems behind them.

This section focuses on practical database operations for local development, troubleshooting, and delivery workflows.

---

## Scope

The Databases layer covers:

- Running databases in containers for local and CI use
- Connecting applications and tools safely
- Basic operational checks (health, logs, readiness)
- Backup and restore fundamentals
- Common failure modes during development and testing

---

## Mental Model

Most database issues in containerized setups map to one of these:

1. Container lifecycle issue (not running, restarting, unhealthy)
2. Connectivity issue (host, port, network, DNS)
3. Credentials/config mismatch (user, password, database name)
4. Data persistence issue (missing volume, wrong mount path)
5. Initialization mismatch (env vars only applied on first init)

---

## Sections

### PostgreSQL with Docker

Understand:

- How to run PostgreSQL with persistent storage
- How to connect with `psql`
- How to execute SQL and inspect state
- How to create backups and restore safely
- How to debug common startup and connection failures

---

## Guiding Principle

For database troubleshooting in containers:

- Verify container state first.
- Verify connectivity second.
- Verify credentials and target database third.
- Verify persistence and initialization logic last.

This order prevents most misdiagnoses.
