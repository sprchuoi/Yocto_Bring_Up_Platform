#!/bin/bash
#
# Raspberry Pi 4 CAN interface setup script with CAN-FD support
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): RPI4-CAN-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up Raspberry Pi 4 CAN interfaces with CAN-FD support..."

# Load CAN kernel modules
modprobe can
modprobe can-raw
modprobe can-bcm
modprobe can-gw
modprobe can-dev
modprobe slcan
modprobe mcp251x
modprobe mcp251xfd

# Configure CAN0 interface (MCP2515 on SPI0.0)
if [ -d /sys/class/net/can0 ]; then
    # Try to configure with CAN-FD first, fallback to classic CAN
    if ip link set can0 type can bitrate 500000 dbitrate 2000000 fd on 2>/dev/null; then
        log_message "CAN0 configured with CAN-FD: 500kbps/2Mbps"
    else
        ip link set can0 type can bitrate 500000
        log_message "CAN0 configured with classic CAN: 500kbps"
    fi
    
    ip link set up can0
    log_message "CAN0 interface is up"
else
    log_message "CAN0 interface not found - check device tree overlay"
fi

# Configure CAN1 interface (MCP2515 on SPI0.1) 
if [ -d /sys/class/net/can1 ]; then
    # Try to configure with CAN-FD first, fallback to classic CAN
    if ip link set can1 type can bitrate 500000 dbitrate 2000000 fd on 2>/dev/null; then
        log_message "CAN1 configured with CAN-FD: 500kbps/2Mbps"
    else
        ip link set can1 type can bitrate 500000
        log_message "CAN1 configured with classic CAN: 500kbps"
    fi
    
    ip link set up can1
    log_message "CAN1 interface is up"
else
    log_message "CAN1 interface not found - check device tree overlay"
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
# CAN interface configuration for Raspberry Pi 4
# This file contains settings for CAN interfaces

# CAN0 - Primary interface (SPI0.0)
# Bitrate: 500kbps (classic CAN), 2Mbps (CAN-FD data)
# Device: MCP2515/MCP251xFD

# CAN1 - Secondary interface (SPI0.1) 
# Bitrate: 500kbps (classic CAN), 2Mbps (CAN-FD data)
# Device: MCP2515/MCP251xFD

# Usage examples:
# Classic CAN: ip link set can0 type can bitrate 500000
# CAN-FD: ip link set can0 type can bitrate 500000 dbitrate 2000000 fd on
#
# Send test message: cansend can0 123#DEADBEEF
# Monitor: candump can0
EOF

# Test CAN interfaces availability
for interface in can0 can1; do
    if ip link show $interface >/dev/null 2>&1; then
        log_message "$interface is available and configured"
        
        # Check if CAN-FD is supported
        if ip -details link show $interface | grep -q "fd"; then
            log_message "$interface supports CAN-FD"
        else
            log_message "$interface supports classic CAN only"
        fi
    fi
done

log_message "Raspberry Pi 4 CAN setup completed"
log_message "Available CAN tools: cansend, candump, canplayer, canlogserver"
log_message "Configuration file: /etc/can/interfaces"