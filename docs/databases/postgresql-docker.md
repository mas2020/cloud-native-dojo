# PostgreSQL with Docker

PostgreSQL in Docker is a standard pattern for local development, integration testing, and repeatable CI workflows.

This page is a practical cheatsheet for the commands you use most: run, connect, inspect, back up, restore, and debug.

---

## What It Is

Running PostgreSQL with Docker means:

- A PostgreSQL server process runs inside a container
- Data is stored in a Docker volume or bind mount
- You connect through mapped host ports or Docker networks
- Initialization is controlled by environment variables and optional init scripts

The official PostgreSQL Docker image initializes a new database cluster on first startup, then reuses existing data on subsequent starts.

---

## When to Use It

Use PostgreSQL with Docker when:

- You need a fast local database for application development
- You want reproducible database setup in CI pipelines
- You need isolated versions across projects
- You want disposable environments for testing migrations
- You need a quick debugging environment for SQL or connection issues

---

## Core Commands

### Pull and Pin an Image Version

```bash
docker pull postgres:18
```

Why it matters:

- Pinning a major version avoids unexpected breaking changes from moving tags
- Aligns local development with the target runtime version

### Run PostgreSQL with Persistent Storage

```bash
docker volume create pgdata

docker run -d \
  --name dojo-postgres \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=appsecret \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  --restart unless-stopped \
  postgres:18
```

Why it matters:

- Named volume preserves data across container restarts/recreation
- `POSTGRES_*` values define initial user/database during first initialization

### Check Container Health and Logs

```bash
docker ps
docker logs dojo-postgres --tail 100
docker logs -f dojo-postgres
docker inspect dojo-postgres --format '{{json .State.Health}}'
docker exec dojo-postgres pg_isready -U appuser -d appdb
```

Why it matters:

- Confirms the server is actually ready to accept connections
- Startup logs usually reveal auth, config, or init-script issues quickly

### Connect with `psql`

From host (if `psql` installed locally):

```bash
psql "host=127.0.0.1 port=5432 dbname=appdb user=appuser password=appsecret sslmode=disable"
```

From inside container:

```bash
docker exec -it dojo-postgres psql -U appuser -d appdb
```

Why it matters:

- Separates client-install issues from server/network issues
- Gives immediate SQL access for verification and troubleshooting

### Run SQL Non-Interactively

Run inline SQL:

```bash
docker exec -i dojo-postgres psql -U appuser -d appdb -c "SELECT now();"
```

Run a local SQL file:

```bash
cat schema.sql | docker exec -i dojo-postgres psql -U appuser -d appdb
```

Why it matters:

- Useful for bootstrapping schemas and automation
- Easy to script in CI and test environments

### Useful `psql` Meta Commands

Inside `psql`:

```sql
\l
\du
\dt
\dn
\d table_name
\conninfo
```

Why it matters:

- Quickly verifies database, role, and table state
- Reduces guesswork during debugging

### Create Database and Role

```bash
docker exec -i dojo-postgres psql -U appuser -d appdb -c "CREATE ROLE service_user LOGIN PASSWORD 'change_me';"
docker exec -i dojo-postgres psql -U appuser -d appdb -c "CREATE DATABASE service_db OWNER service_user;"
docker exec -i dojo-postgres psql -U appuser -d service_db -c "GRANT ALL PRIVILEGES ON DATABASE service_db TO service_user;"
```

Why it matters:

- Helps isolate app credentials per service/environment
- Keeps ownership and permissions explicit

### Back Up and Restore

Plain SQL backup:

```bash
docker exec -t dojo-postgres pg_dump -U appuser -d appdb > appdb.sql
```

Custom-format backup:

```bash
docker exec -t dojo-postgres pg_dump -U appuser -d appdb -Fc > appdb.dump
```

Restore plain SQL:

```bash
cat appdb.sql | docker exec -i dojo-postgres psql -U appuser -d appdb
```

Restore custom-format backup:

```bash
cat appdb.dump | docker exec -i dojo-postgres pg_restore -U appuser -d appdb --clean --if-exists
```

Why it matters:

- Enables safe reset/recovery workflows
- Standardizes migration and local refresh procedures

### Copy Files Between Host and Container

```bash
docker cp dojo-postgres:/var/lib/postgresql/data /tmp/pgdata-copy
docker cp ./seed.sql dojo-postgres:/tmp/seed.sql
docker exec -i dojo-postgres psql -U appuser -d appdb -f /tmp/seed.sql
```

Why it matters:

- Simplifies moving seed files and diagnostics artifacts

### Stop, Start, Restart, Remove

```bash
docker stop dojo-postgres
docker start dojo-postgres
docker restart dojo-postgres
docker rm -f dojo-postgres
```

Remove container and volume (destructive):

```bash
docker rm -f dojo-postgres
docker volume rm pgdata
```

Why it matters:

- Supports clean environment resets
- Keeps destructive cleanup explicit and intentional

### Initialize with SQL or Scripts on First Boot

The image runs scripts in `/docker-entrypoint-initdb.d/` during first initialization only.

```bash
docker run -d \
  --name dojo-postgres-init \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_PASSWORD=appsecret \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  -v "$(pwd)/init:/docker-entrypoint-initdb.d" \
  postgres:18
```

Why it matters:

- Good for repeatable local bootstrap (schema, seed, extensions)
- Critical to remember: these scripts do not rerun on an already initialized data directory

---

## Real-World Example

Scenario: your app fails on startup with `password authentication failed for user`.

Step-by-step workflow:

1. Verify container state and readiness:

```bash
docker ps --filter name=dojo-postgres
docker exec dojo-postgres pg_isready -U appuser -d appdb
```

2. Inspect logs for auth/startup errors:

```bash
docker logs dojo-postgres --tail 200
```

3. Validate current roles/databases directly:

```bash
docker exec -it dojo-postgres psql -U appuser -d appdb -c "\du"
docker exec -it dojo-postgres psql -U appuser -d appdb -c "\l"
```

4. Confirm app connection string matches host/port/db/user:

- host: `127.0.0.1` (or service name in Docker network)
- port: `5432`
- database: `appdb`
- user: `appuser`

5. If credentials were changed after first initialization, recreate with clean data volume:

```bash
docker rm -f dojo-postgres
docker volume rm pgdata
```

Then start again with the desired `POSTGRES_*` values.

Likely outcomes:

- Wrong app credentials or db name in connection string
- Misunderstanding that `POSTGRES_*` vars only apply on first cluster initialization
- Volume reusing old cluster state

---

## Debugging Pattern

Use this repeatable sequence:

1. Check process/container state (`docker ps`, `docker logs`)
2. Check readiness (`pg_isready`)
3. Check connectivity (`psql` from host and from container)
4. Check identity and privileges (`\du`, `\l`, grants)
5. Check initialization assumptions (fresh volume vs existing data)
6. Check backup/restore path for data recovery

Decision shortcuts:

- `connection refused`: server not listening, container stopped, or port not mapped
- `password authentication failed`: wrong credentials or role mismatch
- `database does not exist`: wrong DB name or initialization did not create expected DB
- init scripts not applied: existing data directory prevented first-boot init flow

---

## Common Pitfalls

- Using `latest` tags instead of pinning a major version
- Forgetting a persistent volume and losing data on container removal
- Expecting `POSTGRES_USER`/`POSTGRES_DB`/`POSTGRES_PASSWORD` to update an already initialized cluster
- Publishing `5432` to all interfaces unnecessarily on shared machines
- Storing credentials directly in shell history or committed files
- Running destructive restore flags (`--clean`) against the wrong database
- Assuming container running means database ready; always verify with `pg_isready`
