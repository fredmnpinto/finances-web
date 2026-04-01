# Dockerfile for deploying the Nix-built finances-web package
# Build: docker build -t finances-web .
# Run:   docker run -d -p 3000:3000 -e RAILS_MASTER_KEY=<key> -e DATABASE_URL=<url> finances-web

# Build stage - builds the Nix package
FROM nixos/nix:latest AS builder

WORKDIR /app
COPY . .

# Build the package (output goes to result/)
RUN nix --extra-experimental-features "nix-command flakes" build .#default

# Runtime stage - minimal image with runtime deps
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libjemalloc2 \
        libvips42 \
        postgresql-client \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy nix store (this is large but includes all deps)
COPY --from=builder /nix/store /nix/store

# Copy built application
COPY --from=builder /app/result /app

WORKDIR /app

# Environment
ENV HOME=/app \
    BUNDLE_GEMFILE=/app/Gemfile \
    BUNDLE_PATH=/app/gems \
    PATH=/app/bin:/app/gems/bin:/nix/var/nix/profiles/default/bin:/nix/store/*-bash-*/bin:/nix/store/*-coreutils-*/bin:$PATH \
    LD_LIBRARY_PATH=/nix/store/*-glibc-*/lib:/nix/store/*-vips-*/lib:$LD_LIBRARY_PATH \
    LOCALE_ARCHIVE=/nix/store/*-glibc-*/lib/locale/locale-archive \
    RAILS_ENV=production \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

EXPOSE 3000

CMD ["/app/bin/finances-web"]
