#!/bin/bash

# Function to display the top 10 applications consuming the most CPU and memory
top_applications() {
    echo "Top 10 Applications by CPU Usage:"
    ps aux --sort=-%cpu | head -n 11
    echo
    echo "Top 10 Applications by Memory Usage:"
    ps aux --sort=-%mem | head -n 11
}

# Function to monitor network statistics
network_monitoring() {
    echo "Network Monitoring:"
    echo "Number of concurrent connections:"
    ss -s | grep 'estab' | awk '{print $4}'
    echo "Packet Drops:"
    netstat -i | grep -vE 'Kernel|Iface|lo' | awk '{print $1 " " $4}'
    echo "Network Traffic (MB in and out):"
    ifconfig | grep 'RX packets' | awk '{print "Received: " $5/1024/1024 " MB"}'
    ifconfig | grep 'TX packets' | awk '{print "Transmitted: " $5/1024/1024 " MB"}'
}

# Function to monitor disk usage
disk_usage() {
    echo "Disk Usage:"
    df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
    do
        usep=$(echo $output | awk '{ print $1}' | sed s/%//g)
        partition=$(echo $output | awk '{ print $2 }')
        if [ $usep -ge 80 ]; then
            echo "Warning: Partition $partition is at $usep% usage."
        else
            echo "Partition $partition is at $usep% usage."
        fi
    done
}

# Function to display system load and CPU usage breakdown
system_load() {
    echo "System Load:"
    uptime
    echo
    echo "CPU Usage Breakdown:"
    mpstat | grep 'all'
}

# Function to monitor memory usage
memory_usage() {
    echo "Memory Usage:"
    free -h
    echo "Swap Memory Usage:"
    swapon --show
}

# Function to monitor processes
process_monitoring() {
    echo "Process Monitoring:"
    echo "Number of active processes:"
    ps aux | wc -l
    echo "Top 5 Processes by CPU Usage:"
    ps aux --sort=-%cpu | head -n 6
    echo "Top 5 Processes by Memory Usage:"
    ps aux --sort=-%mem | head -n 6
}

# Function to monitor essential services
service_monitoring() {
    echo "Service Monitoring:"
    for service in sshd nginx apache2 iptables; do
        if systemctl is-active --quiet $service; then
            echo "$service is running."
        else
            echo "$service is not running."
        fi
    done
}

# Function to display the full dashboard
dashboard() {
    clear
    echo "==== SYSTEM MONITOR DASHBOARD ===="
    echo
    top_applications
    echo
    network_monitoring
    echo
    disk_usage
    echo
    system_load
    echo
    memory_usage
    echo
    process_monitoring
    echo
    service_monitoring
    echo
}

# Parse command-line switches
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -cpu) top_applications; shift ;;
        -network) network_monitoring; shift ;;
        -disk) disk_usage; shift ;;
        -load) system_load; shift ;;
        -memory) memory_usage; shift ;;
        -process) process_monitoring; shift ;;
        -services) service_monitoring; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# If no switch is provided, display the full dashboard
if [ "$#" -eq 0 ]; then
    while true; do
        dashboard
        sleep 5
    done
fi


