# Openkoda Monolithic Container

Single-container image bundling **Openkoda 1.7.1**, **PostgreSQL 14**, and **Mailpit** for local SMTP capture.

## Quick start

```bash
chmod +x .openkoda/build_and_run.sh .openkoda/publish_image.sh
./.openkoda/build_and_run.sh
```

Then open **http://localhost:8080** and sign in with `admin` / `admin123`.

Captured emails: **http://localhost:8025**

## What this image does

| Component | Role |
|-----------|------|
| PostgreSQL 14 | Application database (pre-initialized at image build time) |
| Openkoda 1.7.1 | Built from this repository's source during `docker build` |
| Mailpit | Local SMTP sink on port 1025 |
| Supervisor | Starts services via `/openkoda/entrypoint.sh` |

Database schema and admin user are created during the **Docker build**, not on first container start, so runtime startup stays fast.

## Version pinning

The image always builds Openkoda from the checked-out source tree. The release line is pinned via:

- `ARG OPENKODA_VERSION=1.7.1` in `.openkoda/Dockerfile`
- Default image tag `openkoda-monolith:1.7.1` in `build_and_run.sh`

To target another release, check out that git tag/commit before building.

## Ports

| Port | Service |
|------|---------|
| 8080 | Openkoda web UI |
| 8025 | Mailpit web UI |
| 1025 | Mailpit SMTP |

## Apple Silicon (M1/M2/M3)

The build script defaults to `linux/amd64` for compatibility. On ARM hosts this uses QEMU emulation and the first build can take a while.

Override if needed:

```bash
DOCKER_PLATFORM=linux/arm64 ./.openkoda/build_and_run.sh
```

## Publish to AWS ECR

1. Create repository: `openkoda/app-openkoda-monolith` (or set `OPENKODA_ECR_REPO`).
2. Configure AWS credentials.
3. Run:

```bash
./.openkoda/publish_image.sh
```

Environment overrides:

- `OPENKODA_APP_SLUG` — short name used in ECR repo naming
- `OPENKODA_ECR_REPO` — full ECR repository name
- `AWS_REGION` — AWS region (default `us-east-1`)

## Layout

```
.openkoda/
├── Dockerfile
├── supervisord.conf
├── entrypoint.sh          → installed as /openkoda/entrypoint.sh
├── config/
│   └── application-override.properties
├── scripts/
│   ├── start-postgres.sh
│   ├── start-openkoda.sh
│   └── start-mailpit.sh
├── build_and_run.sh
├── publish_image.sh
└── README.md
```

## Notes

- Uses **HTTP** with `secure.cookie=false` for straightforward local access.
- All dockerization files live under `.openkoda/`; application source is not modified.
- First `docker build` compiles Openkoda with Maven and may take 15–30 minutes depending on network and CPU.
- PostgreSQL on Ubuntu stores config in `/etc/postgresql/14/main/` (not inside the data directory). The runtime start script must pass `config_file` and `hba_file` explicitly, matching what `service postgresql start` does during the image build.
