# Installing and Updating Go on Ubuntu

Go is distributed as a self-contained tarball from the official Go website.

The recommended installation method is a manual tarball install to `/usr/local/go`, giving you full control over the version and no dependency on system package managers.

---

## What It Is

The official Go toolchain includes:

- `go` — the build tool, test runner, and module manager
- `gofmt` — the standard code formatter
- `godoc` — documentation viewer
- The Go standard library

The canonical install path is `/usr/local/go`, with the Go binary at `/usr/local/go/bin/go`.

---

## When to Use It

Use this method when:

- You need a specific Go version not available in `apt`
- You want reproducible toolchain installations across machines
- You are upgrading from an older Go version
- You are setting up a CI environment or developer workstation on Ubuntu

---

## Core Commands

### Check the Current Go Version

```bash
go version
```

Why it matters:

- Confirms the active version before upgrading or after installing
- Verifies the binary in `PATH` is the one you expect

### Find the Latest Go Version

Check the available releases at https://go.dev/dl/ or use `curl`:

```bash
curl -s https://go.dev/VERSION?m=text
```

Why it matters:

- Gives you the exact version string to use in the download URL
- Avoids manually browsing the release page

### Download the Go Tarball

```bash
GO_VERSION=1.24.1
curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
```

Why it matters:

- `curl -L` follows redirects from the official download URL
- `-O` saves the file using the remote filename
- Pinning `GO_VERSION` makes the command auditable and repeatable

### Verify the Download Checksum

```bash
sha256sum go${GO_VERSION}.linux-amd64.tar.gz
```

Compare the output against the checksum listed at https://go.dev/dl/ for the release.

Why it matters:

- Detects corrupted downloads before installing
- Confirms the binary matches the published release

### Remove the Previous Go Installation

```bash
sudo rm -rf /usr/local/go
```

Why it matters:

- The official upgrade method is a full replacement — no in-place upgrade
- Leaving the old directory causes a mixed installation if you extract on top

!!! warning
    This command deletes the current Go toolchain. Only run it after downloading the new tarball and confirming a valid checksum.

### Extract and Install

```bash
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
```

Why it matters:

- Extracts the tarball to `/usr/local`, creating `/usr/local/go`
- `-C` sets the target directory; the tarball itself contains a `go/` subdirectory
- No build step required — Go ships as a pre-compiled binary

### Add Go to PATH

If Go is not yet in your `PATH`, add it to your shell profile:

```bash
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile
```

For Zsh users:

```bash
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.zshrc
source ~/.zshrc
```

Why it matters:

- The Go binary is at `/usr/local/go/bin/go`; it must be on `PATH` to invoke it by name
- `source` applies the change immediately without opening a new shell

### Configure GOPATH (Optional but Recommended)

```bash
echo 'export GOPATH=$HOME/go' >> ~/.profile
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.profile
source ~/.profile
```

Why it matters:

- `GOPATH/bin` is where `go install` places binaries (e.g., `golangci-lint`, `dlv`)
- Setting it explicitly avoids relying on the default `~/go` path being implicit

### Verify the Installation

```bash
go version
go env GOROOT
go env GOPATH
```

Why it matters:

- `go version` confirms the installed version
- `go env GOROOT` confirms the toolchain root matches `/usr/local/go`
- `go env GOPATH` confirms the workspace path is configured correctly

---

## Real-World Example

Scenario: upgrade from Go 1.22 to Go 1.24.1 on an Ubuntu developer workstation.

1. Confirm the current version:

```bash
go version
# go version go1.22.0 linux/amd64
```

2. Set the target version and download the tarball:

```bash
GO_VERSION=1.24.1
curl -LO "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
```

3. Verify the checksum against https://go.dev/dl/:

```bash
sha256sum go${GO_VERSION}.linux-amd64.tar.gz
```

4. Remove the old installation:

```bash
sudo rm -rf /usr/local/go
```

5. Extract the new version:

```bash
sudo tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
```

6. Verify the upgrade succeeded:

```bash
go version
# go version go1.24.1 linux/amd64
go env GOROOT
# /usr/local/go
```

7. Clean up the downloaded tarball:

```bash
rm go${GO_VERSION}.linux-amd64.tar.gz
```

---

## Debugging Pattern

Use this sequence when Go is not working after install or upgrade:

1. Check if the binary is found:

```bash
which go
# Expected: /usr/local/go/bin/go
```

2. If `which go` returns nothing, check `PATH`:

```bash
echo $PATH | tr ':' '\n' | grep go
```

3. Check if the profile was sourced:

```bash
source ~/.profile   # or ~/.zshrc for Zsh
which go
```

4. Confirm the installation directory exists:

```bash
ls /usr/local/go/bin/go
```

5. Check `GOROOT` and `GOPATH`:

```bash
go env GOROOT
go env GOPATH
```

Decision shortcuts:

- `go: command not found`: binary not on `PATH`; source your profile or open a new shell
- `go env GOROOT` shows wrong path: another Go installation is taking precedence; check `/usr/bin/go` or `snap`-installed Go
- `permission denied` on `/usr/local/go`: extraction ran without `sudo`

---

## Common Pitfalls

- Extracting the tarball on top of an existing `/usr/local/go` directory without removing it first — causes mixed versions
- Using `apt install golang-go` — the APT package is frequently multiple versions behind the current release
- Forgetting to source the shell profile after modifying `PATH` — the new binary is not visible in the current session
- Not adding `$GOPATH/bin` to `PATH` — binaries installed with `go install` are not accessible by name
- Skipping the checksum verification — risks installing a corrupted or tampered binary
- Installing as root but running as a regular user without `PATH` alignment — leads to version mismatches between `sudo go` and `go`
