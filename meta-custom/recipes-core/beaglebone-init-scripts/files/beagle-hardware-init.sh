#!/bin/bash
#
# BeagleBone Hardware Initialization Script
# Industrial/IoT Configuration: CAN, UART, SPI, WiFi (no UI dependencies)
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): BEAGLE-HARDWARE-INIT: $1" | tee -a "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_message "=========================================="
log_message "BeagleBone Industrial Hardware Init v1.0.0"
log_message "=========================================="

# Check if we're running on BeagleBone
if grep -q "AM33XX" /proc/cpuinfo; then
    log_message "Confirmed: Running on BeagleBone (AM33XX)"
else
    log_message "Warning: Not running on BeagleBone"
fi

# Set script directory
SCRIPT_DIR="$(dirname "$0")"

# ===================================================================
# SYSTEM CONFIGURATION
# ===================================================================

log_message "Configuring system for industrial operation..."

# Disable unnecessary services for headless operation
DISABLE_SERVICES=(
    "bluetooth.service"
    "gdm.service"
    "lightdm.service"
    "x11-common.service"
    "avahi-daemon.service"
)

for service in "${DISABLE_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        systemctl disable "$service" 2>/dev/null || true
        systemctl stop "$service" 2>/dev/null || true
        log_message "Disabled service: $service"
    fi
done

# Enable essential services
ENABLE_SERVICES=(
    "systemd-networkd.service"
    "systemd-resolved.service"
    "ssh.service"
)

for service in "${ENABLE_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        systemctl enable "$service" 2>/dev/null || true
        log_message "Enabled service: $service"
    fi
done

# ===================================================================
# HARDWARE INTERFACE INITIALIZATION
# ===================================================================

# Initialize CAN interfaces
log_message "Initializing CAN interfaces..."
if [ -f "$SCRIPT_DIR/beagle-can-setup.sh" ]; then
    bash "$SCRIPT_DIR/beagle-can-setup.sh"
else
    log_message "CAN setup script not found"
fi

# Initialize UART interfaces
log_message "Initializing UART interfaces..."
if [ -f "$SCRIPT_DIR/beagle-uart-setup.sh" ]; then
    bash "$SCRIPT_DIR/beagle-uart-setup.sh"
else
    log_message "UART setup script not found"
fi

# Initialize SPI interfaces
log_message "Initializing SPI interfaces..."
if [ -f "$SCRIPT_DIR/beagle-spi-setup.sh" ]; then
    bash "$SCRIPT_DIR/beagle-spi-setup.sh"
else
    log_message "SPI setup script not found"
fi

# Initialize WiFi
log_message "Initializing WiFi..."
if [ -f "$SCRIPT_DIR/beagle-wifi-setup.sh" ]; then
    bash "$SCRIPT_DIR/beagle-wifi-setup.sh"
else
    log_message "WiFi setup script not found"
fi

# ===================================================================
# MONITORING AND DIAGNOSTICS SETUP
# ===================================================================

log_message "Setting up monitoring and diagnostics..."

# Create system info script
cat > /usr/local/bin/beagle-system-info <<'EOF'
#!/bin/bash
# BeagleBone System Information

echo "===== BeagleBone Industrial System Information ====="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo ""

echo "===== Hardware ====="
echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Board: $(cat /proc/device-tree/model 2>/dev/null | tr -d '\0' || echo "Unknown")"
echo ""

echo "===== Network Interfaces ====="
ip -brief addr show
echo ""

echo "===== CAN Interfaces ====="
for can in can0 can1; do
    if ip link show $can >/dev/null 2>&1; then
        echo "$can: $(ip -details link show $can | grep -o 'state [A-Z]*' | cut -d' ' -f2)"
    fi
done
echo ""

echo "===== Hardware Interfaces ====="
echo "SPI devices: $(ls /dev/spidev* 2>/dev/null | wc -l)"
echo "I2C devices: $(ls /dev/i2c-* 2>/dev/null | wc -l)"
echo "UART devices: $(ls /dev/ttyO* /dev/ttyS* 2>/dev/null | wc -l)"
echo ""

echo "===== Storage ====="
df -h / /boot
echo ""

echo "===== Configuration Version ====="
cat /etc/beaglebone/version 2>/dev/null || echo "Version file not found"
EOF

chmod +x /usr/local/bin/beagle-system-info
log_message "Created system info utility: beagle-system-info"

# ===================================================================
# COMPLETION
# ===================================================================

log_message "=========================================="
log_message "BeagleBone Hardware Initialization Complete"
log_message "=========================================="

log_message "Configured features:"
log_message "  ✓ Headless operation (no UI)"
log_message "  ✓ CAN bus support"
log_message "  ✓ Multiple UART interfaces"
log_message "  ✓ SPI interface support"
log_message "  ✓ WiFi support (USB adapters)"
log_message "  ✓ Industrial IoT tools"

log_message ""
log_message "Available utilities:"
log_message "  - beagle-system-info: System status and diagnostics"

log_message ""
log_message "Configuration files:"
log_message "  - /etc/can/interfaces: CAN bus settings"
log_message "  - /etc/uart/interfaces: UART pin mappings"
log_message "  - /etc/spi/interfaces: SPI pin mappings"

log_message ""
log_message "Log file: $LOG_FILE"
log_message "=========================================="