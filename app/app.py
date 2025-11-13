#!/usr/bin/env python3
"""
Demo application with Prometheus metrics endpoint
Exposes CPU, memory, and HTTP response time metrics
"""

import time
import random
import psutil
from flask import Flask, Response
from prometheus_client import Counter, Gauge, Histogram, generate_latest, REGISTRY

app = Flask(__name__)

# Define Prometheus metrics
REQUEST_COUNT = Counter(
    'app_requests_total',
    'Total number of requests',
    ['method', 'endpoint', 'status']
)

CPU_USAGE = Gauge(
    'app_cpu_usage_percent',
    'Current CPU usage percentage'
)

MEMORY_USAGE = Gauge(
    'app_memory_usage_bytes',
    'Current memory usage in bytes'
)

MEMORY_USAGE_PERCENT = Gauge(
    'app_memory_usage_percent',
    'Current memory usage percentage'
)

REQUEST_DURATION = Histogram(
    'app_request_duration_seconds',
    'Request duration in seconds',
    ['method', 'endpoint']
)

APP_HEALTH = Gauge(
    'app_health_status',
    'Application health status (1=healthy, 0=unhealthy)'
)

# Simulate health status (can be toggled for testing)
healthy = True


def update_system_metrics():
    """Update CPU and memory metrics"""
    try:
        # Get CPU usage
        cpu_percent = psutil.cpu_percent(interval=0.1)
        CPU_USAGE.set(cpu_percent)
        
        # Get memory usage
        memory = psutil.virtual_memory()
        MEMORY_USAGE.set(memory.used)
        MEMORY_USAGE_PERCENT.set(memory.percent)
        
        # Set health status
        APP_HEALTH.set(1 if healthy else 0)
    except Exception as e:
        print(f"Error updating metrics: {e}")


@app.route('/')
def index():
    """Main endpoint"""
    start_time = time.time()
    
    update_system_metrics()
    
    # Simulate some work
    time.sleep(random.uniform(0.01, 0.1))
    
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method='GET', endpoint='/').observe(duration)
    REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
    
    return {
        'status': 'healthy' if healthy else 'unhealthy',
        'message': 'Demo application for observability setup',
        'endpoints': {
            '/': 'Main endpoint',
            '/metrics': 'Prometheus metrics',
            '/health': 'Health check',
            '/stress': 'Trigger CPU stress (for testing alerts)',
            '/toggle-health': 'Toggle health status'
        }
    }


@app.route('/health')
def health():
    """Health check endpoint"""
    start_time = time.time()
    
    update_system_metrics()
    
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method='GET', endpoint='/health').observe(duration)
    
    status = 200 if healthy else 503
    REQUEST_COUNT.labels(method='GET', endpoint='/health', status=str(status)).inc()
    
    return {'status': 'healthy' if healthy else 'unhealthy'}, status


@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    update_system_metrics()
    return Response(generate_latest(REGISTRY), mimetype='text/plain')


@app.route('/stress')
def stress():
    """Simulate CPU stress for testing alerts"""
    start_time = time.time()
    
    # Simulate high CPU usage
    end = time.time() + 5  # Run for 5 seconds
    while time.time() < end:
        _ = [i**2 for i in range(10000)]
    
    update_system_metrics()
    
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method='GET', endpoint='/stress').observe(duration)
    REQUEST_COUNT.labels(method='GET', endpoint='/stress', status='200').inc()
    
    return {'message': 'CPU stress completed', 'duration': f'{duration:.2f}s'}


@app.route('/toggle-health')
def toggle_health():
    """Toggle application health status"""
    global healthy
    healthy = not healthy
    
    update_system_metrics()
    
    REQUEST_COUNT.labels(method='GET', endpoint='/toggle-health', status='200').inc()
    
    return {'status': 'healthy' if healthy else 'unhealthy', 'message': f'Health status toggled to: {"healthy" if healthy else "unhealthy"}'}


if __name__ == '__main__':
    print("Starting demo application on port 8080...")
    print("Endpoints:")
    print("  - http://localhost:8080/ (main)")
    print("  - http://localhost:8080/metrics (Prometheus metrics)")
    print("  - http://localhost:8080/health (health check)")
    print("  - http://localhost:8080/stress (trigger CPU stress)")
    print("  - http://localhost:8080/toggle-health (toggle health status)")
    
    app.run(host='0.0.0.0', port=8080)
