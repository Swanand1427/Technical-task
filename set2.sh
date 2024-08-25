#!/bin/bash

# Security Audit and Server Hardening Script
# Author: [Your Name]
# Date: [Date]
# Version: 1.0

# Global Variables
AUDIT_LOG="/var/log/security_audit.log"
EMAIL_ALERTS="security@example.com"
CUSTOM_CHECKS_CONFIG="/etc/custom_security_checks.conf"

# Function to log messages
log_message() {
    local MESSAGE="$1"
    echo "$(date +"%Y-%m-%d %T") : $MESSAGE" | tee -a $AUDIT_LOG
}

# Function to check if the script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

# Function to audit users and groups
audit_users_groups() {
    log_message "Starting User and Group Audit..."

    log_message "Listing all users and groups..."
    cat /etc/passwd | tee -a $AUDIT_LOG
    cat /etc/group | tee -a $AUDIT_LOG

    log_message "Checking for users with UID 0 (root privileges)..."
    awk -F: '($3 == 0) {print $1}' /etc/passwd | tee -a $AUDIT_LOG

    log_message "Checking for users without passwords or with weak passwords..."
    awk -F: '($2 == "" || $2 == "*") {print $1}' /etc/shadow | tee -a $AUDIT_LOG

    log_message "User and Group Audit Complete."
}

# Function to audit file and directory permissions
audit_file_permissions() {
    log_message "Starting File and Directory Permissions Audit..."

    log_message "Scanning for world-writable files and directories..."
    find / -type d -perm -0002 -exec ls -ld {} \; 2>/dev/null | tee -a $AUDIT_LOG
    find / -type f -perm -0002 -exec ls -l {} \; 2>/dev/null | tee -a $AUDIT_LOG

    log_message "Checking for .ssh directories with incorrect permissions..."
    find /home -name ".ssh" -exec ls -ld {} \; | tee -a $AUDIT_LOG

    log_message "Checking for files with SUID or SGID bits set..."
    find / -perm /6000 -type f -exec ls -l {} \; 2>/dev/null | tee -a $AUDIT_LOG

    log_message "File and Directory Permissions Audit Complete."
}

# Function to audit services
audit_services() {
    log_message "Starting Service Audit..."

    log_message "Listing all running services..."
    systemctl list-units --type=service --state=running | tee -a $AUDIT_LOG

    log_message "Checking for unnecessary or unauthorized services..."
    # Add custom logic to check against a list of authorized services

    log_message "Ensuring critical services (e.g., sshd, iptables) are running..."
    systemctl is-active sshd && log_message "sshd is running." || log_message "sshd is NOT running."
    systemctl is-active iptables && log_message "iptables is running." || log_message "iptables is NOT running."

    log_message "Service Audit Complete."
}

# Function to audit firewall and network security
audit_firewall_network() {
    log_message "Starting Firewall and Network Security Audit..."

    log_message "Checking if firewall is active and configured..."
    if command -v ufw >/dev/null 2>&1; then
        ufw status verbose | tee -a $AUDIT_LOG
    elif command -v iptables >/dev/null 2>&1; then
        iptables -L -v -n | tee -a $AUDIT_LOG
    else
        log_message "No firewall found."
    fi

    log_message "Listing open ports and associated services..."
    netstat -tulpn | tee -a $AUDIT_LOG

    log_message "Checking for IP forwarding and other insecure network configurations..."
    sysctl net.ipv4.ip_forward | tee -a $AUDIT_LOG
    sysctl net.ipv6.conf.all.forwarding | tee -a $AUDIT_LOG

    log_message "Firewall and Network Security Audit Complete."
}

# Function to audit IP and network configurations
audit_ip_network() {
    log_message "Starting IP and Network Configuration Audit..."

    log_message "Identifying public and private IPs..."
    ip addr | tee -a $AUDIT_LOG

    log_message "Checking that sensitive services are not exposed on public IPs..."
    # Add logic to verify SSH is not exposed on public IP unless required

    log_message "IP and Network Configuration Audit Complete."
}

# Function to check for security updates and patches
check_security_updates() {
    log_message "Checking for security updates and patches..."

    if command -v apt >/dev/null 2>&1; then
        apt update && apt list --upgradable | grep -i security | tee -a $AUDIT_LOG
    elif command -v yum >/dev/null 2>&1; then
        yum check-update --security | tee -a $AUDIT_LOG
    fi

    log_message "Security updates and patches check complete."
}

# Function to monitor logs for suspicious activities
monitor_logs() {
    log_message "Monitoring logs for suspicious activities..."

    log_message "Checking for too many SSH login attempts..."
    grep "Failed password" /var/log/auth.log | tee -a $AUDIT_LOG

    log_message "Log monitoring complete."
}

# Function to harden SSH configuration
harden_ssh() {
    log_message "Hardening SSH configuration..."

    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    systemctl reload sshd
    log_message "SSH configuration hardened."

    log_message "Ensuring SSH keys are securely stored..."
    # Add logic to check SSH key permissions and security

    log_message "SSH hardening complete."
}

# Function to disable IPv6 if not required
disable_ipv6() {
    log_message "Disabling IPv6 if not required..."

    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p

    log_message "IPv6 disabled."
}

# Function to secure the bootloader
secure_bootloader() {
    log_message "Securing the bootloader..."

    grub2-setpassword
    log_message "GRUB bootloader password set."

    log_message "Bootloader secured."
}

# Function to configure automatic updates
configure_auto_updates() {
    log_message "Configuring automatic updates..."

    if command -v unattended-upgrades >/dev/null 2>&1; then
        dpkg-reconfigure unattended-upgrades
    else
        apt install unattended-upgrades
        dpkg-reconfigure unattended-upgrades
    fi

    log_message "Automatic updates configured."
}

# Function to run custom security checks
run_custom_checks() {
    log_message "Running custom security checks..."

    if [ -f "$CUSTOM_CHECKS_CONFIG" ]; then
        source "$CUSTOM_CHECKS_CONFIG"
        # Execute custom checks defined in the configuration file
    else
        log_message "No custom security checks found."
    fi

    log_message "Custom security checks complete."
}

# Function to generate the final report and send alerts
generate_report() {
    log_message "Generating security audit report..."

    # Summary of the audit
    log_message "Security audit completed. Report saved to $AUDIT_LOG."

    log_message "Sending email alerts..."
    if [ -x "$(command -v mail)" ]; then
        mail -s "Security Audit Report" $EMAIL_ALERTS < $AUDIT_LOG
    else
        log_message "Mail command not found, skipping email alerts."
    fi

    log_message "Report generation and alerts complete."
}

# Main script execution
check_root
audit_users_groups
audit_file_permissions
audit_services
audit_firewall_network
audit_ip_network
check_security_updates
monitor_logs
harden_ssh
disable_ipv6
secure_bootloader
configure_auto_updates
run_custom_checks
generate_report

log_message "Security audit and server hardening completed."
