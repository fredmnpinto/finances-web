# Log Aggregation with Loki + Grafana

## Overview

Deploy a self-hosted log aggregation system using Grafana Loki (log storage), Grafana (UI/query), and Promtail (log shipper) to centralize Docker container logs on nixserver. Currently logs go to Docker stdout and are difficult to search or tail remotely. This system enables centralized searching, filtering by log level, and container-based queries similar to Kibana but with lightweight resource requirements suitable for an 8GB RAM homelab server.

## User Stories

- As a system administrator, I want all Docker container logs to be automatically collected and stored in Loki, so that I can search across all containers from a single UI.
- As a developer, I want to search logs by container name and filter by log level (debug, info, warn, error), so that I can quickly diagnose issues with specific services.
- As a user, I want a Grafana dashboard accessible via browser to query logs with LogQL, so that I can find specific error messages or patterns.
- As a system administrator, I want automatic log retention (14-30 days), so that disk usage remains bounded without manual cleanup.

## Acceptance Criteria

### Must Have
- [ ] Loki container running and accessible on port 3100
- [ ] Promtail configured to collect all Docker container logs via Docker socket discovery
- [ ] Grafana accessible on port 3000 (or alternative available port)
- [ ] Loki datasource configured in Grafana automatically via provisioning
- [ ] Logs labeled with container name, compose service, and compose project
- [ ] Basic retention configured (14-day minimum)
- [ ] System accessible behind Cloudflare Access like other services
- [ ] Resource limits set to keep total RAM usage under 1GB

### Should Have
- [ ] Search by container name returns only that container's logs
- [ ] Filter by log level (INFO, WARN, ERROR) works via label queries
- [ ] Real-time tail mode available in Grafana Explore
- [ ] Log volume dashboard showing logs/day and storage trends
- [ ] Health checks on all containers with restart policies

### Won't Have
- [ ] Alerting/notification system (not needed for homelab)
- [ ] Multi-tenant access control
- [ ] Object storage backend (local filesystem only)
- [ ] TLS termination (handled by Cloudflare)

## Edge Cases

- **Loki unavailable**: Promtail should buffer logs locally and retry (configured in client settings)
- **Disk full**: Loki retention compactor deletes old logs automatically; monitor disk usage
- **Container restart**: Promtail discovers new containers automatically via Docker SD
- **High log volume**: Rate limiting in Promtail to prevent overwhelming Loki
- **Grafana password**: Must be set via environment variable; default credentials not acceptable

## Dependencies

- [ ] Docker socket accessible to Promtail container (read-only mount)
- [ ] Available ports: 3000 (or 3099+ if conflict), 3100
- [ ] Cloudflare tunnel configured for grafana.nacaratopinto.com
- [ ] Nixserver has sufficient disk for retention period (estimate 10-30GB)

## Technical Constraints

| Component | RAM Limit | Notes |
|-----------|-----------|-------|
| Loki | 512 MB | Single instance, local storage |
| Promtail | 128 MB | Docker service discovery |
| Grafana | 256 MB | Basic UI, minimal dashboards |
| **Total** | **~900 MB** | Leaves headroom for other services |

### Storage Estimation
- Moderate homelab (10-20 containers): ~1 GB/day
- 14-day retention: ~14 GB
- 30-day retention: ~30 GB
- Recommend starting with 14-day retention, adjust based on observed usage

### Transport Options
| Option | Pros | Cons |
|--------|-----|------|
| **Docker logging driver** | Simple, native | Less flexible, harder to debug |
| **Promtail (recommended)** | Full labels, better querying | Extra container |

**Recommendation**: Use Promtail with Docker socket service discovery. It provides better labeling (container name, compose project) and more flexible query capabilities. The Docker logging driver is simpler but limits post-hoc querying.

### Port Allocation
- Loki: 3100 (standard)
- Grafana: Use 3099 if 3000 conflicts with existing service, or 3200