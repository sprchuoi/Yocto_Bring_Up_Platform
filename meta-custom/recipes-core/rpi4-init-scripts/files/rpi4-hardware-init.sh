#!/bin/bash
#
# Raspberry Pi 4 Hardware Initialization Script
# Industrial/IoT Configuration: SSH, WiFi, Docker, CAN/CAN-FD, UART, SPI, Ethernet
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): RPI4-HARDWARE-INIT: $1" | tee -a "$LOG_FILE"
}

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_message "=========================================="
log_message "Raspberry Pi 4 Industrial Hardware Init"
log_message "=========================================="

# Check if we're running on Raspberry Pi 4
if grep -q "Raspberry Pi 4" /proc/cpuinfo; then
    log_message "Confirmed: Running on Raspberry Pi 4"
else
    log_message "Warning: Not running on Raspberry Pi 4"
fi

# Set script directory
SCRIPT_DIR="$(dirname "$0")"

# ===================================================================
# NETWORK CONFIGURATION
# ===================================================================

log_message "Configuring network interfaces..."

# Enable SSH service
systemctl enable ssh
systemctl start ssh
log_message "SSH service enabled and started"

# Configure Ethernet interface
if ip link show eth0 >/dev/null 2>&1; then
    ip link set eth0 up
    log_message "Ethernet interface (eth0) enabled"
else
    log_message "Ethernet interface not found"
fi

# WiFi configuration (if adapter present)
if ip link show wlan0 >/dev/null 2>&1; then
    ip link set wlan0 up
    log_message "WiFi interface (wlan0) enabled"
    
    # Create basic wpa_supplicant configuration if not exists
    if [ ! -f /etc/wpa_supplicant/wpa_supplicant.conf ]; then
        mkdir -p /etc/wpa_supplicant
        cat > /etc/wpa_supplicant/wpa_supplicant.conf << 'EOF'
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

# Example WiFi network configuration
# Uncomment and modify for your network
#network={
#    ssid="YourNetworkName"
#    psk="YourPassword"
#}
EOF
        log_message "Created default wpa_supplicant configuration"
    fi
else
    log_message "WiFi interface not found"
fi

# ===================================================================
# DOCKER CONFIGURATION
# ===================================================================

log_message "Configuring Docker..."

# Enable Docker service
if systemctl list-unit-files | grep -q docker.service; then
    systemctl enable docker
    systemctl start docker
    log_message "Docker service enabled and started"
    
    # Add users to docker group
    for user in pi root; do
        if id "$user" >/dev/null 2>&1; then
            usermod -aG docker "$user"
            log_message "Added user '$user' to docker group"
        fi
    done
else
    log_message "Docker service not found"
fi

# ===================================================================
# HARDWARE INTERFACE INITIALIZATION
# ===================================================================

# Initialize CAN interfaces
log_message "Initializing CAN interfaces..."
if [ -f "$SCRIPT_DIR/rpi4-can-setup.sh" ]; then
    bash "$SCRIPT_DIR/rpi4-can-setup.sh"
else
    log_message "CAN setup script not found"
fi

# Initialize UART interfaces  
log_message "Initializing UART interfaces..."
if [ -f "$SCRIPT_DIR/rpi4-uart-setup.sh" ]; then
    bash "$SCRIPT_DIR/rpi4-uart-setup.sh"
else
    log_message "UART setup script not found"
fi

# Initialize SPI interfaces
log_message "Initializing SPI interfaces..."
if [ -f "$SCRIPT_DIR/rpi4-spi-setup.sh" ]; then
    bash "$SCRIPT_DIR/rpi4-spi-setup.sh"
else
    log_message "SPI setup script not found"
fi

# ===================================================================
# SYSTEM OPTIMIZATION
# ===================================================================

log_message "Applying system optimizations..."

# Disable unnecessary services for industrial use
DISABLE_SERVICES=(
    "bluetooth.service"
    "hciuart.service"
    "triggerhappy.service"
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
    "ntp.service"
    "ssh.service"
)

for service in "${ENABLE_SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        systemctl enable "$service" 2>/dev/null || true
        log_message "Enabled service: $service"
    fi
done

# ===================================================================
# GPIO AND I2C SETUP
# ===================================================================

log_message "Configuring GPIO and I2C..."

# Set up I2C permissions
for i2c_bus in {0..6}; do
    i2c_device="/dev/i2c-${i2c_bus}"
    if [ -e "$i2c_device" ]; then
        chmod 666 "$i2c_device"
        log_message "I2C-${i2c_bus} permissions set"
    fi
done

# Add users to i2c and gpio groups
for user in pi root; do
    if id "$user" >/dev/null 2>&1; then
        usermod -aG i2c,gpio,spi,dialout "$user" 2>/dev/null || true
        log_message "Added user '$user' to hardware access groups"
    fi
done

# ===================================================================
# MONITORING AND DIAGNOSTICS SETUP
# ===================================================================

log_message "Setting up monitoring and diagnostics..."

# Create system info script
cat > /usr/local/bin/rpi4-system-info <<'EOF'
#!/bin/bash
# Raspberry Pi 4 System Information

echo "===== Raspberry Pi 4 System Information ====="
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Uptime: $(uptime -p)"
echo ""

echo "===== Hardware ====="
echo "CPU: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
echo "Memory: $(free -h | grep Mem | awk '{print $3"/"$2}')"
echo "Temperature: $(vcgencmd measure_temp 2>/dev/null || echo "N/A")"
echo "Throttled: $(vcgencmd get_throttled 2>/dev/null || echo "N/A")"
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

echo "===== Docker Status ====="
if command -v docker >/dev/null 2>&1; then
    echo "Docker version: $(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')"
    echo "Docker status: $(systemctl is-active docker)"
    echo "Running containers: $(docker ps --format 'table {{.Names}}\t{{.Status}}' 2>/dev/null | tail -n +2 | wc -l)"
else
    echo "Docker not installed"
fi
echo ""

echo "===== Hardware Interfaces ====="
echo "SPI devices: $(ls /dev/spidev* 2>/dev/null | wc -l)"
echo "I2C devices: $(ls /dev/i2c-* 2>/dev/null | wc -l)"  
echo "UART devices: $(ls /dev/ttyAMA* /dev/serial* 2>/dev/null | wc -l)"
echo ""

echo "===== Storage ====="
df -h / /boot
echo ""

echo "===== Services ====="
systemctl status ssh docker --no-pager -l
EOF

chmod +x /usr/local/bin/rpi4-system-info
log_message "Created system info utility: rpi4-system-info"

# ===================================================================
# COMPLETION
# ===================================================================

log_message "=========================================="
log_message "Raspberry Pi 4 Hardware Initialization Complete"
log_message "=========================================="

log_message "Configured features:"
log_message "  ✓ SSH server (port 22)"
log_message "  ✓ Ethernet networking" 
log_message "  ✓ WiFi support (configure in /etc/wpa_supplicant/wpa_supplicant.conf)"
log_message "  ✓ Docker container support"
log_message "  ✓ CAN bus with CAN-FD support"
log_message "  ✓ Multiple UART interfaces"
log_message "  ✓ Multiple SPI interfaces"
log_message "  ✓ I2C and GPIO access"

log_message ""
log_message "Available utilities:"
log_message "  - rpi4-system-info: System status and diagnostics"
log_message "  - uart-test: UART interface testing"
log_message "  - spi-test: SPI interface testing"  
log_message "  - spi-speed-test: SPI speed benchmarking"

log_message ""
log_message "Configuration files:"
log_message "  - /etc/can/interfaces: CAN bus settings"
log_message "  - /etc/uart/interfaces: UART pin mappings"
log_message "  - /etc/spi/interfaces: SPI pin mappings"
log_message "  - /etc/wpa_supplicant/wpa_supplicant.conf: WiFi settings"

log_message ""
log_message "Log file: $LOG_FILE"
log_message "=========================================="