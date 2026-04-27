# Log Aggregation with Loki + Grafana - Tasks

## Task List

- [ ] T001 - Create directory structure for logging stack (config, data volumes)
- [ ] T002 - Create loki-config.yml with 14-day retention and filesystem storage
- [ ] T003 - Create promtail-config.yml with Docker socket service discovery
- [ ] T004 - Create grafana-provisioning/datasources/loki.yml for auto-provisioned datasource
- [ ] T005 - Create grafana.ini environment configuration
- [ ] T006 - Create compose-logging.yml with Loki, Promtail, Grafana services
- [ ] T007 - Create .env file with GRAFANA_PASSWORD and GitHub OAuth credentials
- [ ] T008 - Create Docker volumes (loki_data, grafana_data)
- [ ] T009 - Deploy logging stack containers
- [ ] T010 - Verify all services are running and healthy
- [ ] T011 - Configure Cloudflare Access tunnel for grafana.nacaratopinto.com
- [ ] T012 - Create documentation (README.md with usage instructions)

## Directory Structure

Create on nixserver at `/etc/nixos/logging/` or `~/Projects/nixserver/logging/`:

```
logging/
├── .env                      # Environment variables (secrets)
├── compose-logging.yml       # Docker Compose services
├── loki-config.yml            # Loki configuration
├── promtail-config.yml       # Promtail configuration
├── grafana.ini               # Grafana environment config
└── grafana-provisioning/
    └── datasources/
        └── loki.yml         # Loki datasource provisioning
```

## Dependencies

- T001 must complete before T002-T007
- T007 must complete before T009 (provides credentials)
- T002-T007 must complete before T009
- T008 must complete before T009 (volumes created)
- T009 must complete before T010
- T010 must complete before T011
- T011 must complete before T012

## Task Details

### T001 - Create directory structure

```bash
mkdir -p logging/grafana-provisioning/datasources
cd logging
```

### T002 - Loki Configuration (loki-config.yml)

- HTTP listen port: 3100
- 14-day retention
- Filesystem storage at /loki/chunks
- Compactor enabled for retention
- Analytics disabled
- Resource limits: 512MB RAM

### T003 - Promtail Configuration (promtail-config.yml)

- HTTP listen port: 9081
- Docker socket discovery at unix:///var/run/docker.sock
- Labels: container_name, compose_project, compose_service, image, stream, cluster, environment
- Batch settings for retry logic
- Resource limits: 128MB RAM

### T004 - Grafana Datasource Provisioning

- Auto-provisioned Loki datasource
- URL: http://loki:3100
- Default datasource
- Non-editable

### T005 - Grafana Environment (grafana.ini)

- Port: 3200 (not 3000 - conflicts with web service)
- Domain: grafana.nacaratopinto.com
- GitHub OAuth enabled
- Analytics disabled

### T006 - Docker Compose (compose-logging.yml)

Services:
- loki: grafana/loki:3.2.0 on port 3100
- promtail: grafana/promtail:3.2.0 with Docker socket mount
- grafana: grafana/grafana:11.4.0 on port 3200

Volumes:
- loki_data (persistent)
- grafana_data (persistent)

### T007 - Environment File (.env)

```
GRAFANA_PASSWORD=<secure-password>
GITHUB_CLIENT_ID=<oauth-client-id>
GITHUB_CLIENT_SECRET=<oauth-client-secret>
```

### T008 - Create Docker Volumes

```bash
docker volume create loki_data
docker volume create grafana_data
```

### T009 - Deploy Stack

```bash
docker compose -f compose-logging.yml up -d
```

### T010 - Verify Services

```bash
# Check all containers running
docker compose -f compose-logging.yml ps

# Check Loki health
curl http://localhost:3100/ready

# Check Grafana health
curl http://localhost:3200/api/health

# Check Promtail health
curl http://localhost:9081/ready
```

### T011 - Cloudflare Access

Add tunnel rule:
- URL: grafana.nacaratopinto.com
- Service: http://localhost:3200
- Access Policy: GitHub OAuth (existing)

### T012 - Documentation (README.md)

Include:
- Service URLs and ports
- How to access Grafana
- Basic LogQL query examples
- Troubleshooting steps
- Log volume estimation

## Effort Estimate

- T001: [Small] - ~10 minutes
- T002: [Small] - ~30 minutes
- T003: [Small] - ~30 minutes
- T004: [Small] - ~15 minutes
- T005: [Small] - ~15 minutes
- T006: [Medium] - ~45 minutes
- T007: [Small] - ~15 minutes
- T008: [Small] - ~10 minutes
- T009: [Small] - ~15 minutes
- T010: [Small] - ~20 minutes
- T011: [Medium] - ~30 minutes (requires Cloudflare access)
- T012: [Small] - ~30 minutes

## Testing/Validation Steps

1. **Container Health**: All three containers should show "healthy" status
2. **Loki API**: `curl http://localhost:3100/ready` returns OK
3. **Grafana API**: `curl http://localhost:3200/api/health` returns JSON with "ok":true
4. **Promtail Discovery**: Logs from other containers appear in Loki after 1-2 minutes
5. **Query Test**: In Grafana Explore, query `{cluster="nixserver"}` returns results
6. **Retention**: After 14 days, old logs automatically deleted (skip - too long to test)

## Port Summary

| Service | Internal Port | External Port | Protocol |
|---------|---------------|---------------|----------|
| Loki    | 3100          | 3100          | HTTP     |
| Promtail| 9081          | - (internal) | HTTP     |
| Grafana | 3200          | 3200          | HTTP     |