# VM Health Check Monitoring Script

A lightweight, production-ready shell script for monitoring the health of Ubuntu virtual machines based on CPU, memory, and disk space utilization.

## Overview

The `vm-health-check.sh` script provides a simple yet effective way to assess the operational health of your Ubuntu VMs. It monitors three critical system metrics and classifies the VM status as either **Healthy** or **Not Healthy** based on configurable thresholds.

### Health Status Definition

- **Healthy**: All system metrics (CPU, Memory, Disk) are below 60% utilization
- **Not Healthy**: Any system metric reaches or exceeds 60% utilization

## Features

- ✅ **Real-time System Monitoring**: Collects live CPU, memory, and disk space metrics
- ✅ **Threshold-based Health Assessment**: Configurable threshold (default: 60%) for determining VM health
- ✅ **Detailed Explanation Mode**: Provides in-depth analysis of unhealthy metrics with recommendations
- ✅ **Color-coded Output**: Visual indicators for quick status identification
- ✅ **Exit Code Support**: Standard Unix exit codes for integration with monitoring systems
- ✅ **No Dependencies**: Uses only standard Ubuntu utilities (`top`, `free`, `df`)
- ✅ **Lightweight**: Minimal resource footprint suitable for frequent execution
- ✅ **Ubuntu Optimized**: Specifically designed and tested for Ubuntu systems

## Installation

1. Clone or download the script:
```bash
git clone <repository-url>
cd ai-devops-api
```

2. Make the script executable:
```bash
chmod +x vm-health-check.sh
```

3. (Optional) Move to a system-wide location:
```bash
sudo cp vm-health-check.sh /usr/local/bin/vm-health-check
```

## Usage

### Basic Health Check
Display the current health status and system metrics:
```bash
./vm-health-check.sh
```

**Output:**
```
Analyzing VM health...
Health Status: Healthy

Virtual Machine Metrics:
  CPU Usage: 32%
  Memory Usage: 45%
  Disk Usage: 28%
```

### Detailed Explanation Mode
Show health status with detailed reasoning and recommendations:
```bash
./vm-health-check.sh explain
```

**Output:**
```
Analyzing VM health...
Health Status: Not Healthy

Virtual Machine Metrics:
  CPU Usage: 72%
  Memory Usage: 45%
  Disk Usage: 85%

Explanation:
  ✗ CPU usage is 72% (threshold: 60%)
  ✗ Disk usage is 85% (threshold: 60%)

  Recommendation(s):
    - CPU: Check running processes and optimize heavy workloads
    - Disk: Free up disk space by removing unused files and archives
```

### Help
Display usage information:
```bash
./vm-health-check.sh --help
```

## Explain Mode

The `explain` argument provides actionable insights when VM health is compromised:

### For CPU Issues
When CPU usage exceeds 60%, the script recommends:
- Analyzing running processes using `top` or `ps`
- Identifying and optimizing resource-heavy applications
- Distributing workloads across multiple cores or instances

### For Memory Issues
When memory usage exceeds 60%, the script recommends:
- Reviewing memory-consuming applications
- Enabling memory swapping if appropriate
- Considering vertical scaling (increasing RAM)

### For Disk Issues
When disk usage exceeds 60%, the script recommends:
- Removing old log files
- Cleaning up temporary files (`/tmp`, `/var/tmp`)
- Archiving and removing unused files and data
- Considering disk expansion

## Exit Codes

The script follows standard Unix exit code conventions for easy integration with monitoring systems:

| Exit Code | Meaning | Description |
|-----------|---------|-------------|
| 0 | Success | VM is Healthy |
| 1 | Failure | VM is Not Healthy |

### Usage in Monitoring Systems

**Cron Job Example:**
```bash
# Check VM health every 5 minutes and log results
*/5 * * * * /usr/local/bin/vm-health-check explain >> /var/log/vm-health.log 2>&1
```

**Conditional Execution:**
```bash
./vm-health-check.sh
if [ $? -eq 0 ]; then
    echo "VM is healthy, continuing operations..."
else
    echo "VM health issues detected, alerting administrators..."
    # Send alert to monitoring system
fi
```

## System Metrics Explained

### CPU Usage
- **Measurement**: Overall CPU utilization across all cores
- **Source**: `top` command
- **Range**: 0-100%
- **Healthy Threshold**: < 60%

### Memory Usage
- **Measurement**: Used memory relative to total available memory
- **Source**: `free` command
- **Range**: 0-100%
- **Healthy Threshold**: < 60%
- **Includes**: Allocated memory minus buffers and cache

### Disk Usage
- **Measurement**: Used disk space on root filesystem (/)
- **Source**: `df` command
- **Range**: 0-100%
- **Healthy Threshold**: < 60%

## Sample Output Scenarios

### Scenario 1: Healthy VM
```bash
$ ./vm-health-check.sh
Analyzing VM health...
Health Status: Healthy

Virtual Machine Metrics:
  CPU Usage: 28%
  Memory Usage: 42%
  Disk Usage: 35%
```

### Scenario 2: High Memory with Explanation
```bash
$ ./vm-health-check.sh explain
Analyzing VM health...
Health Status: Not Healthy

Virtual Machine Metrics:
  CPU Usage: 35%
  Memory Usage: 78%
  Disk Usage: 42%

Explanation:
  ✗ Memory usage is 78% (threshold: 60%)

  Recommendation(s):
    - Memory: Review memory-consuming applications and consider increasing RAM
```

### Scenario 3: Multiple Issues
```bash
$ ./vm-health-check.sh explain
Analyzing VM health...
Health Status: Not Healthy

Virtual Machine Metrics:
  CPU Usage: 65%
  Memory Usage: 88%
  Disk Usage: 92%

Explanation:
  ✗ CPU usage is 65% (threshold: 60%)
  ✗ Memory usage is 88% (threshold: 60%)
  ✗ Disk usage is 92% (threshold: 60%)

  Recommendation(s):
    - CPU: Check running processes and optimize heavy workloads
    - Memory: Review memory-consuming applications and consider increasing RAM
    - Disk: Free up disk space by removing unused files and archives
```

## Integration Examples

### Monitoring Integration
```bash
#!/bin/bash
# Send health status to monitoring platform

HEALTH_CHECK="./vm-health-check.sh"
MONITORING_API="https://monitoring.example.com/api/health"

$HEALTH_CHECK
if [ $? -eq 0 ]; then
    STATUS="healthy"
else
    STATUS="unhealthy"
fi

curl -X POST "$MONITORING_API" \
  -H "Content-Type: application/json" \
  -d "{\"status\":\"$STATUS\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
```

### Alert System
```bash
#!/bin/bash
# Alert on health status changes

SCRIPT="./vm-health-check.sh"
ALERT_EMAIL="devops@example.com"

$SCRIPT explain > /tmp/health_report.txt

if [ $? -ne 0 ]; then
    mail -s "Alert: VM Health Issue Detected" "$ALERT_EMAIL" < /tmp/health_report.txt
fi
```

### Automated Cleanup
```bash
#!/bin/bash
# Trigger cleanup if disk usage is high

./vm-health-check.sh
if [ $? -ne 0 ]; then
    echo "Health check failed, initiating cleanup..."
    
    # Clean old logs
    find /var/log -name "*.log" -mtime +30 -delete
    
    # Clean temp files
    rm -rf /tmp/* /var/tmp/*
    
    # Re-run health check
    ./vm-health-check.sh explain
fi
```

## System Requirements

- **OS**: Ubuntu (16.04 LTS or later)
- **Shell**: Bash 4.0+
- **Utilities**: `top`, `free`, `df` (typically pre-installed)
- **Permissions**: Standard user permissions (no `sudo` required)

## Performance

- **Execution Time**: Typically < 1 second
- **CPU Impact**: Minimal (<0.5%)
- **Memory Usage**: ~2-5 MB
- **Suitable for**: Frequent execution (every 5-60 minutes)

## Troubleshooting

### "Error: Failed to collect system metrics"
This error indicates that one or more metrics couldn't be collected:
```bash
# Check if required commands are available
which top free df

# Verify system has readable /proc filesystem
cat /proc/meminfo | head -5
```

### Unexpected metric values
If metrics appear incorrect:
```bash
# Manually verify each metric
echo "CPU Usage:" && top -bn1 | grep "Cpu(s)"
echo "Memory Usage:" && free
echo "Disk Usage:" && df /
```

### Permission denied
If you get a permission error:
```bash
# Ensure script is executable
ls -la vm-health-check.sh
# Should show: -rwxr-xr-x

# If not, fix permissions
chmod +x vm-health-check.sh
```

## Future Improvements

### Planned Enhancements

- [ ] **Configurable Thresholds**: Allow users to set custom health thresholds (e.g., `--threshold 70`)
- [ ] **Multiple Disk Monitoring**: Support monitoring specific mount points (e.g., `/home`, `/var`)
- [ ] **Network Metrics**: Add network interface utilization monitoring
- [ ] **Temperature Monitoring**: Include CPU temperature checks for hardware health
- [ ] **Swap Usage**: Monitor swap memory utilization
- [ ] **Process Analysis**: Identify top resource-consuming processes
- [ ] **Historical Tracking**: Store metrics for trend analysis
- [ ] **JSON Output**: Machine-readable output format for integration
- [ ] **Database Logging**: Push metrics to time-series databases (InfluxDB, Prometheus)
- [ ] **Alert Notifications**: Built-in support for Slack, PagerDuty, email notifications
- [ ] **Performance Baselines**: Compare current metrics against historical baselines
- [ ] **Load Average**: Include system load average monitoring
- [ ] **Multi-system Monitoring**: Deploy and aggregate health across multiple VMs
- [ ] **Web Dashboard**: Simple web interface for health visualization
- [ ] **Caching**: Option to cache results to reduce system calls

### Contribution Areas

We welcome contributions in the following areas:
- Performance optimizations
- Additional metric types
- Integration examples
- Documentation improvements
- Bug reports and fixes

## License

[Specify your license here - e.g., MIT, Apache 2.0, GPL 3.0]

## Support

For issues, questions, or suggestions:
- Create an issue in the repository
- Contact the DevOps team

## Changelog

### Version 1.0.0 (2026-02-14)
- Initial release
- CPU, Memory, and Disk monitoring
- Basic and explain mode functionality
- Color-coded output
- Unix exit code support

---

**Author**: DevOps Team  
**Last Updated**: February 14, 2026  
**Status**: Production Ready
