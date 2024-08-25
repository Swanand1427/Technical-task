#!/bin/bash

# Function to display the top 10 applications consuming the most CPU and memory
function show_top_apps() {
  echo "Top 10 Most Used Applications (by CPU and Memory)"
  echo "==============================================="
  ps aux --sort=-%cpu,-%mem | awk 'NR<=11 {print $0}' | column -t
  echo
}

# Function to monitor network statistics
function show_network_stats() {
  echo "Network Monitoring"
  echo "=================="
  echo "Concurrent connections: $(netstat -tun | grep ESTABLISHED | wc -l)"
  echo "Packet drops:"
  netstat -i | grep -v "Iface" | awk '{print $1": "$4 " dropped out of "$3+$4" total"}'
  echo "Network Traffic (MB):"
  netstat -e | grep "RX packets\|TX packets" | awk '{print $3/1024/1024 " MB"}' | paste - -
  echo
}

# Function to display disk usage
function show_disk_usage() {
  echo "Disk Usage"
  echo "=========="
  df -h | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
  do
    usep=$(echo $output | awk '{ print $1}' | sed 's/%//')
    partition=$(echo $output | awk '{ print $2 }')
    if [ $usep -ge 80 ]; then
      echo "Warning: $partition is at ${usep}% capacity."
    else
      echo "$partition is at ${usep}% capacity."
    fi
  done
  echo
}

# Function to display system load
function show_system_load() {
  echo "System Load"
  echo "==========="
  uptime
  echo "CPU Breakdown (user, system, idle):"
  mpstat | grep -A 5 "%idle" | tail -n 1 | awk '{print "User: " $3 "%, System: " $5 "%, Idle: " $12 "%"}'
  echo
}

# Function to display memory usage
function show_memory_usage() {
  echo "Memory Usage"
  echo "============"
  free -h | grep -v + | grep -v Swap
  echo "Swap Memory Usage:"
  free -h | grep -v + | grep Swap
  echo
}

# Function to display process monitoring information
function show_process_monitoring() {
  echo "Process Monitoring"
  echo "=================="
  echo "Number of active processes: $(ps aux | wc -l)"
  echo "Top 5 Processes by CPU and Memory:"
  ps aux --sort=-%cpu,-%mem | awk 'NR<=6 {print $0}' | column -t
  echo
}

# Function to monitor essential services
function show_service_monitoring() {
  echo "Service Monitoring"
  echo "=================="
  services=("sshd" "nginx" "apache2" "iptables")
  for service in "${services[@]}"; do
    if systemctl is-active --quiet $service; then
      echo "$service is running"
    else
      echo "Warning: $service is not running"
    fi
  done
  echo
}

# Check for command-line switches and call the respective functions
case $1 in
  -cpu)
    show_top_apps
    ;;
  -network)
    show_network_stats
    ;;
  -disk)
    show_disk_usage
    ;;
  -load)
    show_system_load
    ;;
  -memory)
    show_memory_usage
    ;;
  -processes)
    show_process_monitoring
    ;;
  -services)
    show_service_monitoring
    ;;
  *)
    while true; do
      clear
      show_top_apps
      show_network_stats
      show_disk_usage
      show_system_load
      show_memory_usage
      show_process_monitoring
      show_service_monitoring
      sleep 5
    done
    ;;
esac
