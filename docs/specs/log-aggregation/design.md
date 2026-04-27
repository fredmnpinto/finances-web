# Log Aggregation with Loki + Grafana - Design

## Overview

Deploy a self-hosted log aggregation system using Grafana Loki (log storage), Grafana (UI/query), and Promtail (log shipper) to centralize Docker container logs on nixserver. The system uses Promtail with Docker socket service discovery for flexible labeling and querying capabilities.

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        nixserver (Docker Host)                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐              │
│  │   Loki       │    │   Promtail   │    │   Grafana    │              │
│  │  (log store) │◄───│  (shipper)   │    │    (UI)      │              │
│  │   :3100      │    │  :9081       │    │  :3200       │              │
│  └──────────────┘    └──────────────┘    └──────────────┘              │
│         │                 │                   │                        │
│         │           ┌─────┴─────┐             │                        │
│         │           │ Docker    │             │                        │
│         │           │ Socket    │             │                        │
│         │           └──────────┘             │                        │
│         │                                      │                        │
│         ▼                                      ▼                        │
│  ┌─────────────────────────────────────────────┐                        │
│  │         /var/lib/docker/volumes/loki_data    │                        │
│  │         (local filesystem storage)           │                        │
│  └─────────────────────────────────────────────┘                        │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                        │
│  │ Other Docker Containers (logs collected)   │                        │
│  │ - web :3000    - db :5432                    │                        │
│  │ - registry :5000  - ollama :11434            │                        │
│  │ - woodpecker-server :8000                   │                        │
│  └─────────────────────────────────────────────┘                        │
│                                                                         │
└─────────────────────────────────────────────────────────────────��───────┘
                              │
                              │ HTTP / promtail_discovery
                              ▼
                    ┌─────────────────┐
                    │ Cloudflare     │
                    │ Access         │
                    │ (grafana URL)  │
                    └─────────────────┘
```

### Component Responsibilities

| Component | Type | Responsibility |
|-----------|------|----------------|
| `loki` | Docker service | Log storage with LogQL query engine |
| `promtail` | Docker service | Collects logs from Docker daemon via socket |
| `grafana` | Docker service | UI for querying and visualizing logs |
| `loki_data` | Docker volume | Persistent storage for Loki indices |

### Data Flow

```
Docker Container stdout/stderr
         │
         │ (json-file logging driver - default)
         ▼
┌────────────────────────┐
│  Docker Daemon        │
│  (json log files)     │
└────────────────────────┘
         │
         │ (Docker socket /var/run/docker.sock)
         ▼
┌────────────────────────┐
│  Promtail             │
│  - Reads log files    │
│  - Parses JSON        │
│  - Adds labels:      │
│    * container_name  │
│    * compose_project │
│    * compose_service  │
│    * image           │
└────────────────────────┘
         │
         │ (HTTP POST /loki/api/v1/push)
         ▼
┌────────────────────────┐
│  Loki                  │
│  - Stores chunks      │
│  - Indexes by labels  │
│  - Retention cleanup  │
└────────────────────────┘
         │
         │ (HTTP /loki/api/v1/query)
         ▼
┌────────────────────────┐
│  Grafana              │
│  - Explore view      │
│  - LogQL queries      │
│  - Dashboards        │
└────────────────────────┘
```

## Port Allocation

| Service | Port | Protocol | Notes |
|---------|------|----------|-------|
| Loki | 3100 | HTTP | Standard Loki port |
| Promtail | 9081 | HTTP | Health check only |
| Grafana | 3200 | HTTP | 3000 conflicts with web service |

**Note:** Port 3000 is used by the `web` service, so Grafana uses 3200.

## Storage Configuration

### Loki Data Directory

```yaml
volumes:
  loki_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /var/lib/docker/volumes/loki_data  # Local filesystem
```

### Retention Configuration

```yaml
# loki-config.yml
limits:
  retention_period: 14d  # 14-day retention as per requirements

compactor:
  retention_enabled: true
  working_directory: /tmp/loki-retention
```

### Storage Estimation

| Scenario | Daily Volume | 14-Day Total | 30-Day Total |
|----------|-------------|-------------|--------------|
| Light (5 containers) | ~500 MB | 7 GB | 15 GB |
| Moderate (10 containers) | ~1 GB | 14 GB | 30 GB |
| Heavy (20 containers) | ~2 GB | 28 GB | 60 GB |

**Recommendation:** Start with monitoring, adjust retention if storage allows.

## Configuration

### Loki Configuration (loki-config.yml)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  path_prefix: /loki

  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

  limits:
    retention_period: 14d

schema_config:
  configs:
    - from: 2024-01-01
      store: boltdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 14d
  enforce_metric_name: false
  reject_old_samples: false
  reject_old_samples_max_age: 168h

compactor:
  retention_enabled: true
  working_directory: /tmp/loki-retention

analytics:
  reporting_enabled: false
```

### Promtail Configuration (promtail-config.yml)

```yaml
server:
  http_listen_port: 9081
  grpc_listen_port: 9082

positions:
  filename: /promtail/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push
    batchwait: 1s
    batchsize: 102400
    timeout: 10s

scrape_configs:
  - job_name: docker
    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 10s
    labels:
      cluster: nixserver
      environment: homelab
    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            timestamp: time
          source: log
      - regex:
          expression: "^(?P<stream>stdout|stderr)(?P<timestamp>.*) (?P<message>.*)$"
      - labels:
          stream:
          container_name:
          compose_project:
          compose_service:
          image:
      - timestamp:
          source: timestamp
          format: RFC3339Nano
      - output:
          source: message
```

### Grafana Configuration (grafana-provisioning.yml)

```yaml
apiVersion: 1

datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false
    isDefault: true
```

### Grafana Environment (grafana.ini)

``` ini
[server]
http_port = 3200
domain = grafana.nacaratopinto.com
root_url = https://grafana.nacaratopinto.com

[database]
type = sqlite3
path = /var/lib/grafana/grafana.db

[security]
admin_user = admin
admin_password = ${GRAFANA_PASSWORD}

[users]
disable_login_form = false

[auth.github]
enabled = true
client_id = ${GITHUB_CLIENT_ID}
client_secret = ${GITHUB_CLIENT_SECRET}
allow_sign_up = true

[analytics]
reporting_enabled = false

[unified_alerting]
enabled = true
```

## Docker Compose Service Definitions

### compose-logging.yml

```yaml
version: "3.8"

services:
  loki:
    image: grafana/loki:3.2.0
    ports:
      - "3100:3100"
    volumes:
      - ./loki-config.yml:/etc/loki/local-config.yaml:ro
      - loki_data:/loki
    command: -config.file=/etc/loki/local-config.yaml
    restart: always
    mem_limit: 512m
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3100/ready"]
      interval: 30s
      timeout: 10s
      retries: 3

  promtail:
    image: grafana/promtail:3.2.0
    volumes:
      - ./promtail-config.yml:/etc/promtail/local-config.yaml:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/local-config.yaml
    restart: always
    depends_on:
      - loki
    mem_limit: 128m
    extra_hosts:
      - "host.docker.internal:host-gateway"

  grafana:
    image: grafana/grafana:11.4.0
    ports:
      - "3200:3200"
    volumes:
      - ./grafana-provisioning:/etc/grafana/provisioning:ro
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SERVER_ROOT_URL=https://grafana.nacaratopinto.com
      - GF_SERVER_DOMAIN=grafana.nacaratopinto.com
      - GF_AUTH_GITHUB_ENABLED=true
      - GF_AUTH_GITHUB_ALLOW_SIGN_UP=true
      - GF_AUTH_GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
      - GF_AUTH_GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_ANALYTICS_REPORTING_ENABLED=false
    restart: always
    depends_on:
      - loki
    mem_limit: 256m

volumes:
  loki_data:
    driver: local
  grafana_data:
    driver: local

networks:
  default:
    name: logging
```

## Cloudflare Access Configuration

Add tunnel rule in Cloudflare:

```
URL: grafana.nacaratopinto.com
Service: http://localhost:3200
Access Policy: GitHub OAuth (existing)
```

## Resource Limits Summary

| Component | RAM Limit | CPU Limit | Notes |
|-----------|-----------|-----------|-------|
| Loki | 512 MB | 1 core | Single instance, local storage |
| Promtail | 128 MB | 0.5 core | Docker service discovery |
| Grafana | 256 MB | 1 core | Basic UI, minimal dashboards |
| **Total** | **~900 MB** | **2.5 cores** | Within 8GB RAM budget |

## Integration Points

### Docker Socket Access

Promtail requires read-only access to the Docker socket:
- `/var/run/docker.sock` mounted read-only
- `/var/lib/docker/containers` for log file access

### Labels Collected

| Label | Source | Description |
|-------|--------|-------------|
| `container_name` | Docker metadata | Full container name |
| `compose_project` | Docker label | Compose project (default: project name) |
| `compose_service` | Docker label | Compose service name |
| `image` | Docker metadata | Container image |
| `stream` | Log metadata | stdout or stderr |
| `cluster` | Promtail config | Fixed: "nixserver" |
| `environment` | Promtail config | Fixed: "homelab" |

### Health Checks

| Service | Endpoint | Interval |
|---------|----------|----------|
| Loki | `http://localhost:3100/ready` | 30s |
| Promtail | `http://localhost:9081/ready` | 30s |
| Grafana | `http://localhost:3200/api/health` | 30s |

## Query Examples

### Search All Logs

```
{cluster="nixserver"}
```

### Filter by Container

```
{container_name=~"web.*"}
```

### Filter by Log Level

```
{cluster="nixserver"} | json | level="error"
```

### Real-time Tail

```
{cluster="nixserver"} | json | message != "" | tail
```

## Deployment Steps

1. Copy `compose-logging.yml` to `/etc/nixos/` on nixserver
2. Create configuration files:
   - `loki-config.yml`
   - `promtail-config.yml`
   - `grafana-provisioning/datasources/loki.yml`
3. Set environment variables in `.env`:
   - `GRAFANA_PASSWORD`
   - `GITHUB_CLIENT_ID`
   - `GITHUB_CLIENT_SECRET`
4. Deploy:
   ```bash
   cd /etc/nixos
   docker compose -f compose-logging.yml up -d
   ```
5. Verify:
   ```bash
   docker compose -f compose-logging.yml ps
   curl http://localhost:3100/ready
   curl http://localhost:3200/api/health
   ```

## Monitoring

### Log Volume Dashboard

Create basic Grafana dashboard:

```
Variables:
- $cluster: nixserver
- $container: All

Panels:
1. Logs per minute (rate)
2. Storage usage ( Loki /loki )
3. Container log distribution (pie chart)
4. Recent errors (table)
```

## Future Enhancements

- Alert on error rate threshold
- Long-term storage (object backend)
- Multi-server aggregation