#syntax=docker/dockerfile:1
# Official DependencyVerifier agent image (ghcr.io/dependencyverifier/agent), used by the `container` mode.
# Builds the agent from https://github.com/DependencyVerifier/agent at AGENT_REF:
#   docker build -t depverify-agent .
#   docker build --build-arg AGENT_REF=v0.1.0 -t depverify-agent:0.1.0 .
# Multi-arch (amd64/arm64) and cosign signing happen in CI (not yet set up).

ARG RUST_VERSION=1

# --- Build: static musl binary ------------------------------------------------
FROM rust:${RUST_VERSION}-alpine AS build
RUN apk add --no-cache musl-dev
ARG AGENT_REF=main
ADD https://github.com/DependencyVerifier/agent.git#${AGENT_REF} /src
WORKDIR /src
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    cargo build --release --locked \
 && cp target/release/depverify-agent /depverify-agent

# --- CA certificates (rustls needs them; the final image has no package manager) -
FROM alpine:3 AS certs
RUN apk add --no-cache ca-certificates

# --- Runtime: scratch, non-root ----------------------------------------------
FROM scratch
LABEL org.opencontainers.image.title="depverify-agent" \
      org.opencontainers.image.description="DependencyVerifier agent: inventories what runs in production and reports it over an outbound-only, signed connection." \
      org.opencontainers.image.source="https://github.com/DependencyVerifier/agent-image" \
      org.opencontainers.image.licenses="Apache-2.0"
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /depverify-agent /agent
# Persistent state (private key, anti-replay memory) must live on a volume.
VOLUME ["/var/lib/agent"]
ENV AGENT_MODE=container
USER 65532:65532
ENTRYPOINT ["/agent"]
