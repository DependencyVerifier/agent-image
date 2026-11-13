# DependencyVerifier agent image

`ghcr.io/dependencyverifier/agent`: the [DependencyVerifier agent](https://github.com/DependencyVerifier/agent) as a container image. Add it to a Compose project, or run it as an ECS `DAEMON` service, without installing anything on the host.

- Static binary on `scratch`, non-root, read-only, configured only through environment variables and secrets.
- Docker is read through a GET-only socket proxy (`tecnativa/docker-socket-proxy`); the agent never mounts the socket.
- Multi-arch (amd64, arm64), built from the signed release binaries of the agent, signed with cosign (keyless).

## Usage

See [`compose.example.yaml`](compose.example.yaml). Labels on your services (`dev.depverify.monitor`, `dev.depverify.name`, `dev.depverify.environment`, `dev.depverify.paths`) refine what is monitored. Keep the `monitoring-agent-data` volume: losing it means enrolling and approving the agent again.

## Build

```bash
docker build -t depverify-agent .
docker build --build-arg AGENT_REF=<tag or commit> -t depverify-agent:<version> .
```

The image builds the agent from [`DependencyVerifier/agent`](https://github.com/DependencyVerifier/agent) at `AGENT_REF` (default `main`). To build from a local checkout instead (for example while the agent repository is private):

```bash
docker build --build-context agent-src=../agent -t depverify-agent .
```

## Releases

A tag `vX.Y.Z` of this repository (the version of a published agent release) runs `.github/workflows/release.yml`:
`Dockerfile.release` downloads that release, verifies `SHA256SUMS.minisig` with the project release key (minisign, key
id `EBDDB456A4BF3356`), checks that its trusted comment names this version and the binary of each architecture, then
the image is pushed as `ghcr.io/dependencyverifier/agent:X.Y.Z` and `:latest` (amd64, arm64, with provenance and
SBOM attestations) and signed with cosign through GitHub OIDC. Nothing is compiled: the image holds exactly the
binary a console would serve.

```bash
docker buildx build -f Dockerfile.release --build-arg AGENT_VERSION=0.1.0 --platform linux/amd64,linux/arm64 .
cosign verify ghcr.io/dependencyverifier/agent:0.1.0 \
  --certificate-identity-regexp '^https://github.com/DependencyVerifier/agent-image/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

Pin the image by digest in production (`ghcr.io/dependencyverifier/agent@sha256:…`).

## CI

Lints the Dockerfile (hadolint, `.hadolint.yaml`) and the Compose example, then builds and runs the image. While `DependencyVerifier/agent` is private, the build needs a repository secret `AGENT_REPO_TOKEN` (fine-grained token, *Contents: read* on `agent`); without it the build job is skipped with a notice.

## License

[Apache-2.0](LICENSE).
