#!/bin/bash
#
# BeagleBone CAN interface setup script
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): BEAGLE-CAN-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up BeagleBone CAN interfaces..."

# Load CAN kernel modules
modprobe can
modprobe can-raw
modprobe can-dev
modprobe c_can
modprobe c_can_platform

# Configure CAN0 (if available)
if [ -d /sys/class/net/can0 ]; then
    ip link set can0 type can bitrate 500000
    ip link set up can0
    log_message "CAN0 configured at 500kbps"
else
    log_message "CAN0 interface not found"
fi

# Configure CAN1 (if available)  
if [ -d /sys/class/net/can1 ]; then
    ip link set can1 type can bitrate 500000
    ip link set up can1
    log_message "CAN1 configured at 500kbps"
else
    log_message "CAN1 interface not found"
fi

# Set up CAN interface permissions
chmod 666 /dev/can* 2>/dev/null || true

# Create symbolic links for easy access
ln -sf /dev/can0 /dev/can_primary 2>/dev/null || true
ln -sf /dev/can1 /dev/can_secondary 2>/dev/null || true

# Create CAN configuration directory
mkdir -p /etc/can

# Create CAN interface configuration file
cat > /etc/can/interfaces <<EOF
# CAN interface configuration for BeagleBone
# Standard bitrates: 125k, 250k, 500k, 1000k

# CAN0 - Primary interface 
# Bitrate: 500kbps

# CAN1 - Secondary interface
# Bitrate: 500kbps

# Usage examples:
# ip link set can0 type can bitrate 500000
# cansend can0 123#DEADBEEF
# candump can0
EOF

log_message "BeagleBone CAN setup completed"