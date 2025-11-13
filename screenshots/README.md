# Screenshots Directory

Place your Grafana dashboard screenshots here.

## Required Screenshots:
1. `grafana-dashboard.png` - Main dashboard showing all metrics panels
2. `alert-firing.png` - Screenshot showing an active alert in Prometheus or Grafana

## How to Capture:

### Grafana Dashboard Screenshot:
1. Start the stack: `./setup.sh` or `docker compose up -d`
2. Open http://localhost:3000 in your browser
3. Login with `admin` / `admin`
4. Navigate to "Application Observability Dashboard"
5. Let metrics populate for a few minutes
6. Take a full-page screenshot

### Alert Firing Screenshot:
1. Trigger an alert: `curl http://localhost:8080/stress` (run multiple times)
2. Wait 30 seconds for the alert to fire
3. Open http://localhost:9090/alerts
4. Take a screenshot showing the alert in "FIRING" state
5. Or, open Grafana and navigate to Alerting section

Once captured, move the screenshots to this directory.
