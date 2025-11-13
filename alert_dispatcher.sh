#!/bin/bash

##############################################################################
# Alert Dispatcher Script
# 
# This script fetches active alerts from Prometheus API and logs them locally.
# It simulates an alert dispatch system without needing AlertManager.
#
# Usage: ./alert_dispatcher.sh [prometheus_url] [log_file]
#
# Default prometheus_url: http://localhost:9090
# Default log_file: ./alerts.log
##############################################################################

set -euo pipefail

# Configuration
PROMETHEUS_URL="${1:-http://localhost:9090}"
LOG_FILE="${2:-./alerts.log}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to print colored output
print_colored() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${NC}"
}

# Function to fetch alerts from Prometheus
fetch_alerts() {
    local api_url="${PROMETHEUS_URL}/api/v1/alerts"
    
    if ! curl -s -f "$api_url" > /dev/null 2>&1; then
        log_message "ERROR" "Failed to connect to Prometheus at $PROMETHEUS_URL"
        print_colored "$RED" "❌ Cannot connect to Prometheus API"
        return 1
    fi
    
    curl -s "$api_url"
}

# Function to parse and process alerts
process_alerts() {
    local alerts_json="$1"
    local alert_count=0
    local firing_count=0
    local pending_count=0
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_message "WARNING" "jq is not installed. Install it for better JSON parsing."
        print_colored "$YELLOW" "⚠️  jq not found. Logging raw JSON..."
        log_message "RAW_ALERTS" "$alerts_json"
        return
    fi
    
    # Parse alerts using jq
    local status=$(echo "$alerts_json" | jq -r '.status')
    
    if [ "$status" != "success" ]; then
        log_message "ERROR" "Prometheus API returned error status"
        return 1
    fi
    
    # Extract alerts
    local alerts=$(echo "$alerts_json" | jq -c '.data.alerts[]' 2>/dev/null || echo "")
    
    if [ -z "$alerts" ]; then
        print_colored "$GREEN" "✅ No active alerts at $(date '+%Y-%m-%d %H:%M:%S')"
        log_message "INFO" "No active alerts"
        return 0
    fi
    
    # Process each alert
    while IFS= read -r alert; do
        if [ -z "$alert" ]; then
            continue
        fi
        
        alert_count=$((alert_count + 1))
        
        local alert_name=$(echo "$alert" | jq -r '.labels.alertname')
        local alert_state=$(echo "$alert" | jq -r '.state')
        local severity=$(echo "$alert" | jq -r '.labels.severity // "unknown"')
        local summary=$(echo "$alert" | jq -r '.annotations.summary // "No summary"')
        local description=$(echo "$alert" | jq -r '.annotations.description // "No description"')
        local active_at=$(echo "$alert" | jq -r '.activeAt')
        
        if [ "$alert_state" == "firing" ]; then
            firing_count=$((firing_count + 1))
        elif [ "$alert_state" == "pending" ]; then
            pending_count=$((pending_count + 1))
        fi
        
        # Log alert details
        log_message "ALERT" "=================================================="
        log_message "ALERT" "Alert: $alert_name"
        log_message "ALERT" "State: $alert_state"
        log_message "ALERT" "Severity: $severity"
        log_message "ALERT" "Summary: $summary"
        log_message "ALERT" "Description: $description"
        log_message "ALERT" "Active Since: $active_at"
        log_message "ALERT" "=================================================="
        
        # Print to console with colors
        if [ "$alert_state" == "firing" ]; then
            print_colored "$RED" "🔥 FIRING: $alert_name (Severity: $severity)"
        else
            print_colored "$YELLOW" "⏳ PENDING: $alert_name (Severity: $severity)"
        fi
        
        print_colored "$BLUE" "   └─ $summary"
        
    done <<< "$alerts"
    
    # Summary
    print_colored "$BLUE" "\n📊 Alert Summary:"
    echo "   Total Alerts: $alert_count"
    echo "   Firing: $firing_count"
    echo "   Pending: $pending_count"
    
    log_message "SUMMARY" "Total: $alert_count, Firing: $firing_count, Pending: $pending_count"
}

# Function to run continuous monitoring
monitor_alerts() {
    local interval="${1:-30}"
    
    print_colored "$GREEN" "🔍 Starting alert monitoring (interval: ${interval}s)"
    print_colored "$BLUE" "Prometheus: $PROMETHEUS_URL"
    print_colored "$BLUE" "Log file: $LOG_FILE"
    echo ""
    
    log_message "INFO" "Alert dispatcher started (interval: ${interval}s)"
    
    while true; do
        local alerts_json=$(fetch_alerts)
        
        if [ $? -eq 0 ]; then
            process_alerts "$alerts_json"
        fi
        
        echo ""
        print_colored "$BLUE" "Next check in ${interval}s... (Press Ctrl+C to stop)"
        sleep "$interval"
        echo "---"
        echo ""
    done
}

# Main function
main() {
    print_colored "$GREEN" "╔════════════════════════════════════════════════╗"
    print_colored "$GREEN" "║     Prometheus Alert Dispatcher v1.0          ║"
    print_colored "$GREEN" "╚════════════════════════════════════════════════╝"
    echo ""
    
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Check if running in continuous mode
    if [ "${3:-}" == "--monitor" ] || [ "${3:-}" == "-m" ]; then
        local interval="${4:-30}"
        monitor_alerts "$interval"
    else
        # Single run
        print_colored "$BLUE" "Fetching alerts from: $PROMETHEUS_URL"
        echo ""
        
        local alerts_json=$(fetch_alerts)
        
        if [ $? -eq 0 ]; then
            process_alerts "$alerts_json"
        else
            exit 1
        fi
        
        echo ""
        print_colored "$BLUE" "💾 Alerts logged to: $LOG_FILE"
        print_colored "$YELLOW" "\nTip: Use --monitor flag for continuous monitoring"
        print_colored "$YELLOW" "Example: $0 http://localhost:9090 ./alerts.log --monitor 30"
    fi
}

# Run main function
main "$@"
