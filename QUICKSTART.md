# Quick Start Commands

## Initial Setup (First Time Only)

```bash
# Install Docker Desktop from:
# https://docs.docker.com/desktop/install/mac-install/

# Optional but recommended:
brew install jq
```

## Start the Stack

```bash
./setup.sh
```

Or manually:
```bash
docker compose up -d
```

## Access Services

- **Demo App**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Node Exporter**: http://localhost:9100/metrics

## Quick Tests

```bash
# Generate traffic
curl http://localhost:8080/

# View metrics
curl http://localhost:8080/metrics

# Trigger CPU alert
curl http://localhost:8080/stress

# Toggle health status
curl http://localhost:8080/toggle-health

# Check alerts
./alert_dispatcher.sh

# Monitor alerts continuously (every 30s)
./alert_dispatcher.sh http://localhost:9090 ./alerts.log --monitor 30
```

## View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f app
```

## Stop Services

```bash
# Stop but keep data
docker compose down

# Stop and remove all data (clean slate)
docker compose down -v
```

## Grafana Dashboard

1. Open http://localhost:3000
2. Login: admin/admin
3. Navigate to Dashboards → Application Observability Dashboard

## Screenshot Checklist

1. ✅ Grafana dashboard with metrics → `screenshots/grafana-dashboard.png`
2. ✅ Alert firing in Prometheus → `screenshots/alert-firing.png`

## Project Files

```
✅ docker-compose.yml           - Service definitions
✅ prometheus.yml               - Prometheus config
✅ alert.rules.yml              - Alert definitions
✅ grafana-dashboard.json       - Dashboard config
✅ app/                         - Demo application
✅ alert_dispatcher.sh          - Alert notification script
✅ README.md                    - Full documentation
✅ TESTING.md                   - Complete testing guide
```

## Common Issues

**Docker not found?**
- Install Docker Desktop
- Start Docker Desktop app
- Verify: `docker --version`

**Port already in use?**
- Check: `lsof -i :3000`
- Change ports in docker-compose.yml

**Dashboard empty?**
- Wait 1-2 minutes
- Generate traffic with curl
- Check Prometheus targets: http://localhost:9090/targets

## Success Criteria

- ✅ All 4 services running
- ✅ Prometheus scraping metrics
- ✅ Grafana dashboard showing data
- ✅ Alerts can be triggered
- ✅ Alert dispatcher working
- ✅ Screenshots captured
- ✅ Git repo initialized

**Need detailed instructions? See TESTING.md**
