# Local Observability Stack

A complete local observability setup using **Prometheus**, **Grafana**, and **Node Exporter** to monitor a demo web application running in Docker.

## 📋 Overview

This project demonstrates a production-like observability stack that:
- Monitors a local web service running in Docker
- Collects metrics like CPU, memory, and response time
- Visualizes metrics in a Grafana dashboard
- Triggers alerts when the app becomes unhealthy or CPU usage exceeds 70%
- Dispatches alert notifications via a custom Bash script

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Demo App   │────▶│  Prometheus  │────▶│   Grafana   │
│  (Python)   │     │   (Metrics)  │     │ (Dashboard) │
└─────────────┘     └──────────────┘     └─────────────┘
       │                    │
       │                    │
       ▼                    ▼
┌─────────────┐     ┌──────────────┐
│   /metrics  │     │ Node Exporter│
│  endpoint   │     │ (Host Metrics)│
└─────────────┘     └──────────────┘
                           │
                           ▼
                   ┌──────────────┐
                   │Alert Dispatch│
                   │    Script    │
                   └──────────────┘
```

## 📦 Components

- **Demo App** (Port 8080): Python Flask application exposing Prometheus metrics
- **Prometheus** (Port 9090): Metrics collection and alerting engine
- **Grafana** (Port 3000): Metrics visualization and dashboards
- **Node Exporter** (Port 9100): System-level metrics (CPU, memory, disk, etc.)
- **Alert Dispatcher**: Bash script for fetching and logging alerts

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- jq (optional, for better alert parsing)

### 1. Start the Stack

```bash
cd "/Users/asifhasan/Documents/Scrnario 3"
docker-compose up -d
```

### 2. Verify Services

Check all services are running:
```bash
docker-compose ps
```

You should see 4 containers: `demo-app`, `prometheus`, `grafana`, `node-exporter`

### 3. Access the Services

- **Demo App**: http://localhost:8080
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin)
- **Node Exporter**: http://localhost:9100/metrics

## 📊 Grafana Dashboard

1. Open Grafana at http://localhost:3000
2. Login with `admin` / `admin` (you'll be prompted to change password)
3. Navigate to **Dashboards** → **Application Observability Dashboard**

The dashboard includes:
- **CPU Usage** - Real-time application CPU usage (alert threshold: 70%)
- **Memory Usage** - Application memory consumption
- **Response Time** - Average HTTP request duration
- **Health Status** - Application health indicator
- **Request Rate** - Requests per second by endpoint
- **Status Codes** - Distribution of HTTP response codes

## 🔔 Alerts

### Configured Alert Rules

Located in `alert.rules.yml`:

1. **HighCPUUsage**: Fires when CPU > 70% for 30 seconds
2. **ApplicationUnhealthy**: Fires when health status is 0
3. **ApplicationDown**: Fires when app stops responding
4. **HighMemoryUsage**: Fires when memory > 80% for 1 minute
5. **SlowResponseTime**: Fires when avg response time > 1 second

### View Alerts in Prometheus

Visit http://localhost:9090/alerts to see active alerts.

### Run Alert Dispatcher

Single check:
```bash
./alert_dispatcher.sh
```

Continuous monitoring (checks every 30 seconds):
```bash
./alert_dispatcher.sh http://localhost:9090 ./alerts.log --monitor 30
```

The script will:
- Fetch active alerts from Prometheus API
- Display them in a formatted, colored output
- Log all alerts to `alerts.log` file

## 🧪 Testing Alerts

### Test 1: Trigger High CPU Alert

Visit http://localhost:8080/stress to simulate high CPU usage:
```bash
curl http://localhost:8080/stress
```

This will max out CPU for 5 seconds. If you hit it multiple times, CPU will stay above 70% long enough to fire the alert.

### Test 2: Trigger Unhealthy Status

Toggle the application health status:
```bash
curl http://localhost:8080/toggle-health
```

This makes the app report as unhealthy, triggering the `ApplicationUnhealthy` alert after 15 seconds.

### Test 3: Stop the Application

```bash
docker-compose stop app
```

After 30 seconds, the `ApplicationDown` alert will fire.

Restart it:
```bash
docker-compose start app
```

## 📁 Project Structure

```
.
├── docker-compose.yml              # Docker services definition
├── prometheus.yml                  # Prometheus configuration
├── alert.rules.yml                 # Alert rules definitions
├── grafana-dashboard.json          # Pre-configured dashboard
├── grafana-datasource.yml          # Grafana data source config
├── grafana-dashboard-provider.yml  # Dashboard provisioning config
├── alert_dispatcher.sh             # Alert notification script
├── alerts.log                      # Alert logs (created on first run)
├── README.md                       # This file
└── app/
    ├── Dockerfile                  # App container definition
    ├── requirements.txt            # Python dependencies
    └── app.py                      # Demo application code
```

## 🔍 Exploring Metrics

### Available Metrics from Demo App

Visit http://localhost:8080/metrics to see all exposed metrics:

- `app_cpu_usage_percent` - Current CPU usage
- `app_memory_usage_bytes` - Memory usage in bytes
- `app_memory_usage_percent` - Memory usage percentage
- `app_health_status` - Health status (1=healthy, 0=unhealthy)
- `app_requests_total` - Total HTTP requests (labeled by method, endpoint, status)
- `app_request_duration_seconds` - HTTP request duration histogram

### Query Examples in Prometheus

1. CPU usage over time:
   ```promql
   app_cpu_usage_percent
   ```

2. Request rate (per second):
   ```promql
   rate(app_requests_total[1m])
   ```

3. 95th percentile response time:
   ```promql
   histogram_quantile(0.95, rate(app_request_duration_seconds_bucket[5m]))
   ```

4. Memory usage trend:
   ```promql
   app_memory_usage_percent
   ```

## 🛠️ Useful Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f prometheus
docker-compose logs -f grafana
```

### Restart services
```bash
docker-compose restart
```

### Stop services
```bash
docker-compose down
```

### Stop and remove volumes (clean slate)
```bash
docker-compose down -v
```

### Rebuild app after code changes
```bash
docker-compose up -d --build app
```

### Check Prometheus configuration
```bash
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Check alert rules
```bash
docker-compose exec prometheus promtool check rules /etc/prometheus/alert.rules.yml
```

## 📝 Configuration Details

### Prometheus Scrape Targets

Defined in `prometheus.yml`:
- **prometheus**: Self-monitoring (localhost:9090)
- **demo-app**: Application metrics (app:8080/metrics)
- **node-exporter**: Host metrics (node-exporter:9100/metrics)

Scrape interval: 15 seconds (demo-app: 10 seconds)

### Grafana Auto-Provisioning

Grafana automatically provisions:
- Prometheus data source
- Application Observability Dashboard

No manual configuration needed after startup.

## 🐛 Troubleshooting

### Dashboard not showing?
1. Check if Prometheus is scraping targets: http://localhost:9090/targets
2. Verify all targets are "UP"
3. Check Grafana data source: Settings → Data Sources → Prometheus (should be green)

### Alerts not firing?
1. Visit http://localhost:9090/alerts
2. Check alert state (Inactive/Pending/Firing)
3. Verify alert rules syntax:
   ```bash
   docker-compose exec prometheus promtool check rules /etc/prometheus/alert.rules.yml
   ```

### App not starting?
```bash
docker-compose logs app
```

### Can't access Grafana?
Make sure port 3000 isn't in use:
```bash
lsof -i :3000
```

## 📸 Screenshots

### Grafana Dashboard
![Grafana Dashboard](./screenshots/grafana-dashboard.png)

### Alert Firing
![Alert Triggered](./screenshots/alert-firing.png)

## 🎯 Learning Objectives

This project demonstrates:
- ✅ Setting up Prometheus for metrics collection
- ✅ Instrumenting applications with Prometheus client libraries
- ✅ Creating custom Prometheus metrics (Gauges, Counters, Histograms)
- ✅ Configuring alert rules with thresholds and durations
- ✅ Building Grafana dashboards with multiple visualization types
- ✅ Using Node Exporter for system metrics
- ✅ Container orchestration with Docker Compose
- ✅ Implementing custom alert dispatch mechanisms
- ✅ Best practices for local observability stacks

## 📚 Additional Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Prometheus Client Python](https://github.com/prometheus/client_python)
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## 🤝 Contributing

Feel free to extend this setup:
- Add more alert rules
- Create additional dashboard panels
- Implement different metric types
- Add Alertmanager integration
- Include more exporters (MySQL, Redis, etc.)

## 📄 License

This project is for educational purposes.

---

**Happy Monitoring! 📊🔍**
