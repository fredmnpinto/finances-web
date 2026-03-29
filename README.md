# README

## Overview

This is a Rails 8 application for managing personal finances. It can be deployed using Nix packages, Docker, or a combination of both.

## Development

### With Nix (Recommended)

```bash
# Enter development shell
nix develop

# Install dependencies (if needed)
bundle install

# Set up database
rails db:create db:migrate

# Run the server
rails s
```

### With Docker (Development)

```bash
docker compose up
```

## Deployment

### Option 1: Nix Package

The project includes a Nix flake that builds a self-contained package with precompiled assets.

#### Prerequisites

- Nix with flakes enabled
- PostgreSQL database

#### Build

```bash
nix build
```

The output will be in `result/`.

#### Run

```bash
# Set required environment variables
export RAILS_MASTER_KEY="$(cat config/master.key)"
export DATABASE_URL="postgresql://user:password@host/db"
export RAILS_ENV=production

# Run the server
./result/bin/finances-web
```

### Option 2: Docker (Recommended)

The project includes a Dockerfile that builds the Nix package inside Docker and creates a runnable image.

#### Prerequisites

- Docker
- PostgreSQL (can be run via docker-compose)

#### Build

```bash
docker build -t finances-web .
```

#### Run with Docker Compose

The easiest way to run the app with its dependencies:

```bash
# Set the master key (or export it in your shell)
export RAILS_MASTER_KEY="$(cat config/master.key)"

# Start PostgreSQL and the app
docker compose up -d
```

#### Manual Docker Run

```bash
# Start PostgreSQL
docker run -d --name postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=finances_web_production \
  postgres:16

# Run the app
docker run -d --name finances-web \
  -p 3000:3000 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  -e DATABASE_URL="postgresql://postgres:password@host.docker.internal/finances_web_production" \
  finances-web
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `RAILS_MASTER_KEY` | Yes | Encryption key from `config/master.key` |
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `RAILS_ENV` | No | Environment (default: production) |
| `SECRET_KEY_BASE` | No | Rails secret key (auto-generated if not set) |

## Database Setup

```bash
# Run migrations
docker compose exec app rails db:create db:migrate

# Or with nix run
nix run . -- db:create db:migrate
```

## Cloudflare Tunnel (Deployment)

The application is exposed via Cloudflare Tunnel for secure public access.

### Architecture

- **Tunnel**: `1622d182-312f-4713-b923-cf1c1800daff`
- **Hostnames**:
  - `*.nacaratopinto.com` - All subdomains protected with Cloudflare Access

### Adding a New Subdomain

1. **Update NixOS config** on nixserver (`/etc/nixos/configuration.nix`):

```nix
services.cloudflared = {
  enable = true;
  tunnels = {
    "1622d182-312f-4713-b923-cf1c1800daff" = {
      credentialsFile = "/etc/nixos/cloudflared-tunnel-creds.json";
      default = "http_status:404";
      ingress = {
        "ci.nacaratopinto.com" = "http://localhost:8000";
        "finances.nacaratopinto.com" = "http://localhost:3000";
        # Add new hostname here
        "new-service.nacaratopinto.com" = "http://localhost:PORT";
      };
    };
  };
};
```

2. **Apply changes**:
```bash
sudo nixos-rebuild switch
```

3. **Create DNS record**:
```bash
cloudflared tunnel route dns 1622d182-312f-4713-b923-cf1c1800daff new-service.nacaratopinto.com
```

4. **Access is already protected** - The wildcard policy (`*.nacaratopinto.com`) applies automatically to all subdomains.

### Cloudflare Access

All subdomains are protected by Cloudflare Access with the following policy:

- **Application**: `*.nacaratopinto.com`
- **Action**: Allow
- **Rule**: Include specific emails - fredmnpinto@gmail.com, babinacarato@gmail.com

Users must authenticate via the configured IdP (Google, GitHub, etc.) before accessing any subdomain.

### Webhook Bypass (GitHub → Woodpecker)

GitHub webhooks cannot authenticate through Cloudflare Access. To allow GitHub to trigger Woodpecker builds:

1. **Create a separate Access application** for the webhook endpoint:
   - Go to **Access** > **Applications** > **Add application**
   - Select **Self-hosted**
   - **Domain**: `ci.nacaratopinto.com/api/hook`
   - (or use just `ci.nacaratopinto.com` and it will inherit)

2. **Add a Bypass policy**:
   - **Action**: Bypass
   - **Include**: Everyone

This creates a more specific application that takes precedence over the wildcard, allowing the webhook path to bypass authentication.

### Nixserver Deployment Workflow

When making changes to services running on nixserver (like docker-compose.yml, Cloudflare tunnel config, etc.):

1. **Make changes locally** - Edit files in this repository, NOT directly on nixserver
2. **Commit and push** - Commit changes and push to GitHub
3. **Update nixserver** - SSH into nixserver and pull changes:
   ```bash
   ssh nixserver
   cd /path/to/repo
   git pull
   ```
4. **Restart services** - Restart affected containers:
   ```bash
   docker compose -f /etc/nixos/docker-compose.yml up -d
   # Or for nixos-rebuild:
   sudo nixos-rebuild switch
   ```

**Why?** This ensures all infrastructure changes are version-controlled and reproducible.

### Troubleshooting

```bash
# Check cloudflared status
systemctl status cloudflared-tunnel-1622d182-312f-4713-b923-cf1c1800daff

# View logs
journalctl -u cloudflared-tunnel-1622d182-312f-4713-b923-cf1c1800daff -f

# Test DNS resolution
host new-service.nacaratopinto.com 1.1.1.1
```

## System Dependencies

If running without Docker, you'll need:

- Ruby 3.4
- PostgreSQL 15+
- Node.js 20+
- Yarn
- libvips (for image processing)
