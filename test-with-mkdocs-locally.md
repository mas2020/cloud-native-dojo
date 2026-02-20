# Test MkDocs Locally

This guide runs MkDocs in an isolated Python virtual environment so everything can be removed afterward.

## Prerequisites

- Python 3.10+ installed
- Terminal opened at the repository root (`cloud-native-dojo`)

Check Python:

```bash
python3 --version
```

If you are on Debian/Ubuntu and see this error while creating the venv:

`The virtual environment was not created successfully because ensurepip is not available`

install the venv package first:

```bash
sudo apt update
sudo apt install python3-venv
```

If your system requires a version-specific package, install the one matching your Python version (example for Python 3.12):

```bash
sudo apt install python3.12-venv
```

Then retry:

```bash
python3 -m venv .venv
```

## 1. Create and Activate a Virtual Environment

Create:

```bash
python3 -m venv .venv
```

Activate (macOS/Linux):

```bash
source .venv/bin/activate
```

Activate (Windows PowerShell):

```powershell
.venv\Scripts\Activate.ps1
```

You should now see `(.venv)` in your shell prompt.

## 2. Install Documentation Dependencies

```bash
python -m pip install --upgrade pip
python -m pip install --upgrade -r requirements-docs.txt
```

This installs `mkdocs-material` (latest 9.x), which pulls compatible MkDocs dependencies automatically.

## 3. Run MkDocs Locally (Live Preview)

```bash
python -m mkdocs serve
```

Open:

- `http://127.0.0.1:8000`

MkDocs will auto-reload when you edit files in `docs/` or `mkdocs.yml`.

Stop the server with `Ctrl+C`.

## 4. Run a Strict Build Check (Recommended Before GitHub Workflow)

```bash
python -m mkdocs build --strict
```

This catches warnings/errors early, similar to what CI should enforce.

## Note on MkDocs 2.0

If you see a warning mentioning MkDocs 2.0 incompatibility with Material, that is expected for MkDocs 2.0 pre-release tooling today.

Following the official Material install method (`pip install mkdocs-material`) will keep you on the latest compatible stack.

Check installed versions:

```bash
python -m mkdocs --version
python -m pip show mkdocs-material
```

If your shell uses global tools instead of `.venv`, verify:

```bash
which python
which pip
which mkdocs
```

All three should resolve under `.venv/`.

If they do not, reactivate the environment and retry:

```bash
source .venv/bin/activate
python -m pip install --upgrade --force-reinstall -r requirements-docs.txt
python -m mkdocs build --strict
```

## 5. Optional: Clean Generated Site Output

```bash
rm -rf site
```

## 6. Deactivate and Remove Everything

Deactivate environment:

```bash
deactivate
```

Delete virtual environment (macOS/Linux):

```bash
rm -rf .venv
```

Delete virtual environment (Windows PowerShell):

```powershell
Remove-Item -Recurse -Force .venv
```

After this, your system is back to its previous state.

## Quick Workflow (Copy/Paste)

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install --upgrade -r requirements-docs.txt
python -m mkdocs serve
```
