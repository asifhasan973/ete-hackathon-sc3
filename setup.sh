#!/bin/bash

##############################################################################
# Setup and Start Script for Observability Stack
# 
# This script checks prerequisites and starts the observability stack
##############################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

print_header() {
    print_colored "$BLUE" "╔════════════════════════════════════════════════╗"
    print_colored "$BLUE" "║   Local Observability Stack Setup             ║"
    print_colored "$BLUE" "╚════════════════════════════════════════════════╝"
    echo ""
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        print_colored "$RED" "❌ Docker is not installed"
        echo ""
        print_colored "$YELLOW" "Please install Docker Desktop for macOS:"
        echo "   https://docs.docker.com/desktop/install/mac-install/"
        echo ""
        return 1
    fi
    
    if ! docker info &> /dev/null; then
        print_colored "$RED" "❌ Docker is not running"
        echo ""
        print_colored "$YELLOW" "Please start Docker Desktop and try again"
        return 1
    fi
    
    print_colored "$GREEN" "✅ Docker is installed and running"
    return 0
}

check_jq() {
    if ! command -v jq &> /dev/null; then
        print_colored "$YELLOW" "⚠️  jq is not installed (optional, but recommended for alert_dispatcher.sh)"
        echo "   Install with: brew install jq"
        echo ""
    else
        print_colored "$GREEN" "✅ jq is installed"
    fi
}

start_stack() {
    print_colored "$BLUE" "\n🚀 Starting observability stack..."
    
    if docker compose up -d; then
        print_colored "$GREEN" "✅ All services started successfully!"
        echo ""
        print_colored "$BLUE" "📊 Access points:"
        echo "   • Demo App:     http://localhost:8080"
        echo "   • Prometheus:   http://localhost:9090"
        echo "   • Grafana:      http://localhost:3000 (admin/admin)"
        echo "   • Node Exporter: http://localhost:9100/metrics"
        echo ""
        print_colored "$YELLOW" "⏳ Waiting for services to be ready..."
        sleep 10
        
        print_colored "$BLUE" "\n🔍 Service Status:"
        docker compose ps
        
        echo ""
        print_colored "$GREEN" "🎉 Setup complete!"
        echo ""
        print_colored "$BLUE" "Next steps:"
        echo "   1. Open Grafana: http://localhost:3000"
        echo "   2. Login with admin/admin"
        echo "   3. View the 'Application Observability Dashboard'"
        echo "   4. Test alerts: curl http://localhost:8080/stress"
        echo "   5. Run alert dispatcher: ./alert_dispatcher.sh --monitor"
        echo ""
    else
        print_colored "$RED" "❌ Failed to start services"
        return 1
    fi
}

main() {
    print_header
    
    if ! check_docker; then
        exit 1
    fi
    
    check_jq
    
    start_stack
}

main "$@"
