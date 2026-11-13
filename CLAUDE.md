# DependencyVerifier agent image

Builds `ghcr.io/dependencyverifier/agent` from the [`agent`](https://github.com/DependencyVerifier/agent) repository (`ADD …agent.git#${AGENT_REF}`), plus the Compose example users copy.

> **Spec and design** live in the [`DependencyVerifier/.github`](https://github.com/DependencyVerifier/.github) repository: `docs/cadrage.md` (spec, French), `docs/design.md` (UI charter), `docs/brand/` (logo, social images). Any `docs/…` path in this repository refers to that repository.

**Read first:** `docs/cadrage.md` §6bis (container mode, `AGENT_SCOPE`, labels, socket proxy).

## Rules

- `scratch` + CA certificates, **non-root**, `ENTRYPOINT ["/agent"]`, config only via env vars and secrets; state volume `/var/lib/agent` must persist.
- The agent **never mounts the Docker socket**: only the `tecnativa/docker-socket-proxy` sidecar does, GET only (`CONTAINERS=1`, `IMAGES=1`, `INFO=1`, `VERSION=1`, `POST=0`), on an `internal: true` network.
- Hardening in examples: `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges:true`; images pinned by digest.
- Local build from a checkout of the agent: `docker build --build-context agent-src=../agent .` (the `agent-src` stage is the agent's sources).
- CI (`.github/workflows/ci.yml`): hadolint, Compose example validation, image build + smoke test (skipped while `agent` is private and `AGENT_REPO_TOKEN` is unset).
- Release (`.github/workflows/release.yml`, tag `vX.Y.Z` = an agent release): `Dockerfile.release` downloads the signed release binaries of the agent and verifies them on the build platform (minisign with the project release key `RWRWM7…`, trusted comment naming the version, SHA-256), never compiles; multi-arch (amd64, arm64) push to `ghcr.io/dependencyverifier/agent:X.Y.Z` and `:latest` with provenance and SBOM, then keyless cosign signature (GitHub OIDC). Both Dockerfiles are linted by hadolint (`.hadolint.yaml`).
- Commits: subject line only, `type: Capitalized imperative subject`, no body, no trailer.
