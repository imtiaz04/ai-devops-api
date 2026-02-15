#!/bin/bash

#############################################################################
# Script: vm-health-check.sh
# Purpose: Monitor Ubuntu VM health based on CPU, Memory, and Disk Space
# 
# Health Status:
#   - Healthy: All parameters (CPU, Memory, Disk) are less than 60% utilized
#   - Not Healthy: Any parameter is more than or equal to 60% utilized
#
# Usage:
#   ./vm-health-check.sh              # Display health status
#   ./vm-health-check.sh explain      # Display health status with explanation
#############################################################################

set -o pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables to store metrics
CPU_USAGE=0
MEMORY_USAGE=0
DISK_USAGE=0
EXPLAIN_MODE=false
UNHEALTHY_REASONS=()

#############################################################################
# Function: get_cpu_usage
# Purpose: Calculate CPU usage percentage
# Returns: CPU usage as a whole number percentage
#############################################################################
get_cpu_usage() {
    # Get CPU stats from /proc/stat
    # The calculation uses: 100 * (change in busy time) / (change in total time)
    
    local cpu_usage=0
    
    # Use 'top' command with non-interactive mode for single iteration
    # This gets average CPU usage across all cores
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
    
    echo "$cpu_usage"
}

#############################################################################
# Function: get_memory_usage
# Purpose: Calculate memory usage percentage
# Returns: Memory usage as a whole number percentage
#############################################################################
get_memory_usage() {
    local memory_usage=0
    
    # Extract memory info from /proc/meminfo
    # Calculate: (MemTotal - MemAvailable) / MemTotal * 100
    memory_usage=$(free | grep Mem | awk '{printf("%.0f", ($3 / $2) * 100)}')
    
    echo "$memory_usage"
}

#############################################################################
# Function: get_disk_usage
# Purpose: Calculate disk usage percentage for root filesystem
# Returns: Disk usage as a whole number percentage
#############################################################################
get_disk_usage() {
    local disk_usage=0
    
    # Use 'df' command to get disk usage of root filesystem
    # Extract the usage percentage and remove the '%' character
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    echo "$disk_usage"
}

#############################################################################
# Function: check_health
# Purpose: Determine VM health status based on metrics
# Sets HEALTH_STATUS and populates UNHEALTHY_REASONS array globally
#############################################################################
check_health() {
    HEALTH_STATUS="Healthy"
    UNHEALTHY_REASONS=()
    
    # Check CPU usage
    if (( CPU_USAGE >= 60 )); then
        HEALTH_STATUS="Not Healthy"
        UNHEALTHY_REASONS+=("CPU usage is ${CPU_USAGE}% (threshold: 60%)")
    fi
    
    # Check Memory usage
    if (( MEMORY_USAGE >= 60 )); then
        HEALTH_STATUS="Not Healthy"
        UNHEALTHY_REASONS+=("Memory usage is ${MEMORY_USAGE}% (threshold: 60%)")
    fi
    
    # Check Disk usage
    if (( DISK_USAGE >= 60 )); then
        HEALTH_STATUS="Not Healthy"
        UNHEALTHY_REASONS+=("Disk usage is ${DISK_USAGE}% (threshold: 60%)")
    fi
}

#############################################################################
# Function: print_health_status
# Purpose: Display health status with optional explanation
#############################################################################
print_health_status() {
    local health_status=$1
    
    # Print health status with color coding
    if [[ "$health_status" == "Healthy" ]]; then
        echo -e "${GREEN}Health Status: $health_status${NC}"
    else
        echo -e "${RED}Health Status: $health_status${NC}"
    fi
    
    # Print detailed metrics
    echo ""
    echo "Virtual Machine Metrics:"
    echo "  CPU Usage: ${CPU_USAGE}%"
    echo "  Memory Usage: ${MEMORY_USAGE}%"
    echo "  Disk Usage: ${DISK_USAGE}%"
    
    # If explain mode is enabled, print reasons
    if [[ "$EXPLAIN_MODE" == true ]]; then
        echo ""
        echo "Explanation:"
        if [[ "$health_status" == "Healthy" ]]; then
            echo "  ✓ All metrics are below the 60% threshold"
            echo "  ✓ CPU usage (${CPU_USAGE}%) is under control"
            echo "  ✓ Memory usage (${MEMORY_USAGE}%) is under control"
            echo "  ✓ Disk usage (${DISK_USAGE}%) is under control"
        else
            for reason in "${UNHEALTHY_REASONS[@]}"; do
                echo "  ✗ $reason"
            done
            echo ""
            echo "  Recommendation(s):"
            
            # Provide recommendations based on unhealthy metrics
            for reason in "${UNHEALTHY_REASONS[@]}"; do
                if [[ $reason == *"CPU"* ]]; then
                    echo "    - CPU: Check running processes and optimize heavy workloads"
                fi
                if [[ $reason == *"Memory"* ]]; then
                    echo "    - Memory: Review memory-consuming applications and consider increasing RAM"
                fi
                if [[ $reason == *"Disk"* ]]; then
                    echo "    - Disk: Free up disk space by removing unused files and archives"
                fi
            done
        fi
    fi
}

#############################################################################
# Main Script Logic
#############################################################################

# Parse command line arguments
if [[ $# -gt 0 ]]; then
    case "$1" in
        explain)
            EXPLAIN_MODE=true
            ;;
        *)
            echo "Usage: $0 [explain]"
            echo ""
            echo "Arguments:"
            echo "  explain    Show detailed explanation of health status"
            echo ""
            echo "Examples:"
            echo "  $0              # Display basic health status"
            echo "  $0 explain      # Display health status with explanation"
            exit 1
            ;;
    esac
fi

# Collect metrics
echo "Analyzing VM health..." >&2

CPU_USAGE=$(get_cpu_usage)
MEMORY_USAGE=$(get_memory_usage)
DISK_USAGE=$(get_disk_usage)

# Validate that we got numeric values
if ! [[ "$CPU_USAGE" =~ ^[0-9]+$ ]] || ! [[ "$MEMORY_USAGE" =~ ^[0-9]+$ ]] || ! [[ "$DISK_USAGE" =~ ^[0-9]+$ ]]; then
    echo "Error: Failed to collect system metrics" >&2
    exit 1
fi

# Determine health status (this sets HEALTH_STATUS and UNHEALTHY_REASONS globally)
check_health

# Print results
print_health_status "$HEALTH_STATUS"

# Exit with appropriate code
if [[ "$HEALTH_STATUS" == "Healthy" ]]; then
    exit 0
else
    exit 1
fi
