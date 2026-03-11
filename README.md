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

## System Dependencies

If running without Docker, you'll need:

- Ruby 3.4
- PostgreSQL 15+
- Node.js 20+
- Yarn
- libvips (for image processing)
