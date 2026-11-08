# DependencyVerifier agent image

Builds `ghcr.io/dependencyverifier/agent` from the [`agent`](https://github.com/DependencyVerifier/agent) repository (`ADD …agent.git#${AGENT_REF}`), plus the Compose example users copy.

> **Spec and design** live in the [`DependencyVerifier/.github`](https://github.com/DependencyVerifier/.github) repository: `docs/cadrage.md` (spec, French), `docs/design.md` (UI charter), `docs/brand/` (logo, social images). Any `docs/…` path in this repository refers to that repository.

**Read first:** `docs/cadrage.md` §6bis (container mode, `AGENT_SCOPE`, labels, socket proxy).

## Rules

- `scratch` + CA certificates, **non-root**, `ENTRYPOINT ["/agent"]`, config only via env vars and secrets; state volume `/var/lib/agent` must persist.
- The agent **never mounts the Docker socket**: only the `tecnativa/docker-socket-proxy` sidecar does, GET only (`CONTAINERS=1`, `IMAGES=1`, `INFO=1`, `VERSION=1`, `POST=0`), on an `internal: true` network.
- Hardening in examples: `read_only: true`, `cap_drop: [ALL]`, `no-new-privileges:true`; images pinned by digest.
- Later: multi-arch build (amd64/arm64), cosign signature and publication on ghcr.io in CI.
- Commits: subject line only, `type: Capitalized imperative subject`, no body, no trailer.
