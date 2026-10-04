# first-devops-project

An end-to-end DevOps learning project: a small Python API taken from source code to a monitored, reproducible deployment.

The app itself is intentionally simple. The point is the pipeline around it.

## Architecture

```
  git push
     |
     v
  +----------+     +---------+     +---------+     +--------------+
  |  GitHub  | --> | Jenkins | --> | Docker  | --> | Kubernetes   |
  |  (repo)  |     |  (CI)   |     | (image) |     | (OrbStack)   |
  +----------+     +---------+     +---------+     +--------------+
                                                          |
                                                          v
                                                   +--------------+
                                                   |  Prometheus  |
                                                   |   Grafana    |
                                                   +--------------+
```

Infrastructure is defined in Terraform so the whole stack can be destroyed and rebuilt from code.

## Stack

| Layer | Tool |
|---|---|
| App | Python, Flask |
| CI | Jenkins |
| Containers | Docker |
| Orchestration | Kubernetes (OrbStack) |
| Monitoring | Prometheus, Grafana |
| Infrastructure as Code | Terraform |

## Run locally

```bash
cd app
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
.venv/bin/python app.py
```

The app listens on **port 5001** (macOS AirPlay Receiver occupies 5000).

## Endpoints

| Path | Purpose |
|---|---|
| `/` | Greeting, container hostname, app version |
| `/health` | Liveness and readiness probe target |
| `/metrics` | Prometheus metrics |

## Tests

```bash
cd app
.venv/bin/pytest -v
```

## Configuration

All optional, with defaults:

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `5001` | Listen port |
| `GREETING` | `Hello from the DevOps demo app` | Message returned by `/` |
| `APP_VERSION` | `dev` | Version reported by `/` |
