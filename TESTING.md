# Testing Guide

This guide walks you through testing the complete observability stack after Docker is installed.

## Prerequisites

1. **Install Docker Desktop for macOS**
   - Download from: https://docs.docker.com/desktop/install/mac-install/
   - Start Docker Desktop
   - Verify: `docker --version` and `docker compose version`

2. **Install jq (Optional but Recommended)**
   ```bash
   brew install jq
   ```

## Step-by-Step Testing

### 1. Start the Stack

```bash
./setup.sh
```

Or manually:
```bash
docker compose up -d
```

Wait about 10-20 seconds for all services to initialize.

### 2. Verify All Services Are Running

```bash
docker compose ps
```

Expected output should show 4 services all "Up":
- demo-app
- prometheus
- grafana
- node-exporter

### 3. Test the Demo Application

```bash
# Check main endpoint
curl http://localhost:8080/

# Check metrics endpoint
curl http://localhost:8080/metrics

# Check health endpoint
curl http://localhost:8080/health
```

Expected: JSON responses showing application status and Prometheus metrics.

### 4. Verify Prometheus is Scraping Targets

1. Open http://localhost:9090/targets in browser
2. You should see 3 targets, all showing "UP" state:
   - prometheus
   - demo-app
   - node-exporter

If any target is "DOWN", wait a few more seconds and refresh.

### 5. Access Grafana Dashboard

1. Open http://localhost:3000
2. Login:
   - Username: `admin`
   - Password: `admin`
   - (You'll be prompted to change password - you can skip this)
3. Click on **Dashboards** icon (four squares) on the left sidebar
4. Select **Application Observability Dashboard**

You should see 6 panels:
- Application CPU Usage
- Application Memory Usage
- Average Response Time
- Application Health Status
- Request Rate (per second)
- Requests by Status Code

### 6. Generate Some Traffic

Run this in a loop to generate metrics:

```bash
# Generate traffic for 1 minute
for i in {1..60}; do
  curl -s http://localhost:8080/ > /dev/null
  curl -s http://localhost:8080/health > /dev/null
  sleep 1
done
```

Watch the Grafana dashboard update in real-time!

### 7. Test Alert: High CPU Usage

**Trigger the alert:**

```bash
# Run multiple times to sustain high CPU
curl http://localhost:8080/stress &
curl http://localhost:8080/stress &
curl http://localhost:8080/stress &
```

**Monitor the alert:**

1. Open http://localhost:9090/alerts
2. Find "HighCPUUsage" alert
3. Initial state: **Inactive**
4. After CPU spikes: **Pending** (yellow)
5. After 30 seconds above threshold: **Firing** (red)

**Screenshot this for deliverables!**

### 8. Test Alert: Application Unhealthy

**Trigger the alert:**

```bash
curl http://localhost:8080/toggle-health
```

**Verify:**

```bash
curl http://localhost:8080/health
# Should return 503 with "unhealthy" status
```

**Monitor the alert:**

1. Open http://localhost:9090/alerts
2. Find "ApplicationUnhealthy" alert
3. After 15 seconds: Should be **Firing**

**Toggle back to healthy:**

```bash
curl http://localhost:8080/toggle-health
```

### 9. Test Alert Dispatcher Script

**Single check:**

```bash
./alert_dispatcher.sh
```

Expected output:
- Colored, formatted list of active alerts
- Summary count (Total/Firing/Pending)
- Alerts logged to `alerts.log`

**Continuous monitoring:**

```bash
./alert_dispatcher.sh http://localhost:9090 ./alerts.log --monitor 30
```

This will check for alerts every 30 seconds. Press Ctrl+C to stop.

**View alert logs:**

```bash
cat alerts.log
```

### 10. Explore Prometheus Queries

Open http://localhost:9090 and try these queries:

1. **CPU Usage Over Time:**
   ```promql
   app_cpu_usage_percent
   ```

2. **Request Rate:**
   ```promql
   rate(app_requests_total[1m])
   ```

3. **Average Response Time:**
   ```promql
   rate(app_request_duration_seconds_sum[1m]) / rate(app_request_duration_seconds_count[1m])
   ```

4. **Memory Usage:**
   ```promql
   app_memory_usage_percent
   ```

5. **Health Status:**
   ```promql
   app_health_status
   ```

Click "Graph" tab to visualize each query.

### 11. Capture Screenshots (REQUIRED)

#### Screenshot 1: Grafana Dashboard

1. Make sure metrics are populated (generate traffic first)
2. Open http://localhost:3000
3. Go to "Application Observability Dashboard"
4. Take a full-page screenshot showing all 6 panels with data
5. Save as `screenshots/grafana-dashboard.png`

#### Screenshot 2: Alert Firing

**Option A - Prometheus:**
1. Trigger CPU alert: Run `curl http://localhost:8080/stress` multiple times
2. Wait 30-45 seconds
3. Open http://localhost:9090/alerts
4. Screenshot showing alert in "FIRING" state (red)
5. Save as `screenshots/alert-firing.png`

**Option B - Alert Dispatcher:**
1. Run `./alert_dispatcher.sh` while alert is firing
2. Screenshot the terminal output showing the red "FIRING" alert
3. Save as `screenshots/alert-firing.png`

### 12. Verify Alert Rules Configuration

```bash
# Check if rules are loaded
docker compose exec prometheus promtool check rules /etc/prometheus/alert.rules.yml

# Reload Prometheus configuration
curl -X POST http://localhost:9090/-/reload
```

## Common Test Scenarios

### Scenario 1: Sustained High CPU
```bash
# Terminal 1: Generate sustained CPU load
while true; do curl http://localhost:8080/stress & sleep 3; done

# Terminal 2: Monitor alerts
watch -n 5 ./alert_dispatcher.sh
```

### Scenario 2: Application Recovery
```bash
# Stop app
docker compose stop app

# Wait 30 seconds - ApplicationDown alert fires

# Restart app
docker compose start app

# Alert should clear
```

### Scenario 3: Load Testing
```bash
# Install apache bench if not available
# brew install httpd

# Generate 1000 requests with 10 concurrent
ab -n 1000 -c 10 http://localhost:8080/

# Watch response time metrics in Grafana
```

## Validation Checklist

- [ ] All 4 Docker containers running
- [ ] Prometheus targets all "UP"
- [ ] Grafana dashboard accessible
- [ ] Metrics displaying in dashboard
- [ ] CPU alert triggered and fired
- [ ] Health alert triggered and fired
- [ ] Alert dispatcher script works
- [ ] Alerts logged to file
- [ ] Screenshot 1: Grafana dashboard captured
- [ ] Screenshot 2: Alert firing captured
- [ ] Git repository initialized
- [ ] All files committed to git

## Cleanup

Stop all services:
```bash
docker compose down
```

Remove volumes (complete cleanup):
```bash
docker compose down -v
```

Restart fresh:
```bash
docker compose down -v
docker compose up -d
```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs

# Check specific service
docker compose logs app
```

### Grafana dashboard empty
- Wait 1-2 minutes for metrics to populate
- Generate traffic with curl commands
- Check Prometheus targets are UP

### Alerts not firing
- Check alert rules: http://localhost:9090/rules
- Verify targets are being scraped: http://localhost:9090/targets
- Check for syntax errors:
  ```bash
  docker compose exec prometheus promtool check rules /etc/prometheus/alert.rules.yml
  ```

### Port conflicts
If ports 8080, 9090, 3000, or 9100 are in use:
```bash
# Find process using port
lsof -i :3000

# Kill process or edit docker-compose.yml to use different ports
```

## Next Steps

After successful testing:

1. **Document your findings** in a test report
2. **Customize the dashboard** - Add more panels in Grafana
3. **Add more alerts** - Edit `alert.rules.yml`
4. **Extend the app** - Add more metrics in `app/app.py`
5. **Integrate with real services** - Replace demo app with actual application

## Success Criteria

✅ All services running and accessible  
✅ Metrics being collected and displayed  
✅ Alerts configured and firing correctly  
✅ Alert dispatcher logging alerts  
✅ Screenshots captured  
✅ Git repository committed  

**You've successfully built a complete local observability stack!** 🎉
