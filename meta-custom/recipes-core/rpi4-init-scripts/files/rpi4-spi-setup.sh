#!/bin/bash
#
# Raspberry Pi 4 SPI interface setup script
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): RPI4-SPI-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up Raspberry Pi 4 SPI interfaces..."

# SPI device mapping on Raspberry Pi 4:
# SPI0: /dev/spidev0.0, /dev/spidev0.1 (GPIO 7-11)
# SPI1: /dev/spidev1.0, /dev/spidev1.1, /dev/spidev1.2 (GPIO 16-21) 
# SPI2: /dev/spidev2.0, /dev/spidev2.1, /dev/spidev2.2 (GPIO 40-45)
# SPI3: /dev/spidev3.0, /dev/spidev3.1, /dev/spidev3.2 (overlay)
# SPI4: /dev/spidev4.0, /dev/spidev4.1, /dev/spidev4.2 (overlay)
# SPI5: /dev/spidev5.0, /dev/spidev5.1, /dev/spidev5.2 (overlay)
# SPI6: /dev/spidev6.0, /dev/spidev6.1, /dev/spidev6.2 (overlay)

# Set up SPI device permissions
for spi_bus in {0..6}; do
    for chip_select in {0..2}; do
        spi_device="/dev/spidev${spi_bus}.${chip_select}"
        
        if [ -e "$spi_device" ]; then
            chmod 666 "$spi_device"
            log_message "SPI${spi_bus}.${chip_select} ($spi_device) configured"
            
            # Create convenient symlinks
            ln -sf "$spi_device" "/dev/spi${spi_bus}_${chip_select}" 2>/dev/null || true
        fi
    done
done

# Add user to spi group for SPI access (if user exists)
if id "pi" >/dev/null 2>&1; then
    usermod -a -G spi pi 2>/dev/null || true
    log_message "Added user 'pi' to spi group"
fi

if id "root" >/dev/null 2>&1; then
    usermod -a -G spi root 2>/dev/null || true
    log_message "Added user 'root' to spi group"
fi

# Create SPI configuration directory
mkdir -p /etc/spi

# Create SPI configuration file with GPIO mapping
cat > /etc/spi/interfaces <<EOF
# SPI interface configuration for Raspberry Pi 4
# This file contains GPIO pin mappings and settings

# SPI0 - Main SPI bus (enabled by default)
# Devices: /dev/spidev0.0, /dev/spidev0.1
# GPIO: MOSI=10, MISO=9, SCLK=11, CE0=8, CE1=7
# Max Speed: 125MHz

# SPI1 - Additional SPI bus (overlay: spi1-1cs, spi1-2cs, spi1-3cs)
# Devices: /dev/spidev1.0, /dev/spidev1.1, /dev/spidev1.2  
# GPIO: MOSI=20, MISO=19, SCLK=21, CE0=18, CE1=17, CE2=16
# Max Speed: 125MHz

# SPI2 - Additional SPI bus (overlay: spi2-1cs, spi2-2cs, spi2-3cs)
# Devices: /dev/spidev2.0, /dev/spidev2.1, /dev/spidev2.2
# GPIO: MOSI=40, MISO=35, SCLK=38, CE0=36, CE1=37, CE2=39
# Max Speed: 125MHz

# SPI3-6 - Available via overlays
# Overlays: spi3-1cs, spi4-1cs, spi5-1cs, spi6-1cs (and 2cs variants)

# SPI Clock Modes:
# Mode 0: CPOL=0, CPHA=0 (clock idle low, data captured on rising edge)
# Mode 1: CPOL=0, CPHA=1 (clock idle low, data captured on falling edge) 
# Mode 2: CPOL=1, CPHA=0 (clock idle high, data captured on falling edge)
# Mode 3: CPOL=1, CPHA=1 (clock idle high, data captured on rising edge)

# Usage examples:
# Test: spi-config -d /dev/spidev0.0 -s 1000000 -b 8
# Send: echo -e "\\x01\\x02\\x03" | spi-pipe -d /dev/spidev0.0
EOF

# Create SPI test utility
cat > /usr/local/bin/spi-test <<'EOF'
#!/bin/bash
# SPI testing utility for Raspberry Pi 4

if [ $# -lt 1 ]; then
    echo "Usage: $0 <spi_device> [speed] [mode]"
    echo "Example: $0 /dev/spidev0.0 1000000 0"
    echo ""
    echo "Available SPI devices:"
    ls -la /dev/spidev* 2>/dev/null || echo "  No SPI devices found"
    echo ""
    echo "Speed: SPI clock frequency in Hz (default: 1000000)"
    echo "Mode: SPI mode 0-3 (default: 0)"
    exit 1
fi

SPI_DEV="$1"
SPEED="${2:-1000000}"
MODE="${3:-0}"

if [ ! -e "$SPI_DEV" ]; then
    echo "Error: Device $SPI_DEV not found"
    echo "Check if SPI is enabled and overlays are loaded"
    exit 1
fi

echo "Testing SPI device: $SPI_DEV"
echo "Speed: $SPEED Hz, Mode: $MODE"

# Test with spi-tools if available
if command -v spi-config >/dev/null 2>&1; then
    echo "Testing SPI configuration..."
    spi-config -d "$SPI_DEV" -q
    
    echo "Sending test data: 0xAA 0x55 0xFF 0x00"
    echo -e "\\xAA\\x55\\xFF\\x00" | spi-pipe -d "$SPI_DEV" -s "$SPEED" -m "$MODE"
else
    echo "spi-tools not available, using basic test"
    echo "Device exists and is accessible: $SPI_DEV"
    
    # Basic permission test
    if [ -r "$SPI_DEV" ] && [ -w "$SPI_DEV" ]; then
        echo "Device permissions: OK"
    else
        echo "Device permissions: FAILED"
        echo "Try: sudo chmod 666 $SPI_DEV"
    fi
fi
EOF

chmod +x /usr/local/bin/spi-test

# Create SPI speed test utility
cat > /usr/local/bin/spi-speed-test <<'EOF'
#!/bin/bash
# SPI speed testing utility

SPI_DEV="${1:-/dev/spidev0.0}"

if [ ! -e "$SPI_DEV" ]; then
    echo "Error: Device $SPI_DEV not found"
    exit 1
fi

echo "SPI Speed Test for $SPI_DEV"
echo "=========================="

# Test various speeds
SPEEDS=(100000 500000 1000000 2000000 5000000 10000000 20000000)

for speed in "${SPEEDS[@]}"; do
    echo -n "Testing ${speed} Hz... "
    
    if command -v spi-config >/dev/null 2>&1; then
        if timeout 2s spi-config -d "$SPI_DEV" -s "$speed" -q >/dev/null 2>&1; then
            echo "OK"
        else
            echo "FAILED"
        fi
    else
        echo "spi-tools required"
        break
    fi
done
EOF

chmod +x /usr/local/bin/spi-speed-test

log_message "Created SPI test utilities:"
log_message "  /usr/local/bin/spi-test - Basic SPI testing"
log_message "  /usr/local/bin/spi-speed-test - Speed testing"
log_message "Raspberry Pi 4 SPI setup completed"
log_message "Configuration file: /etc/spi/interfaces"
log_message "Available tools: spitools, spi-test, spi-speed-test"

# List available SPI devices
spi_count=0
for spi_bus in {0..6}; do
    for chip_select in {0..2}; do
        spi_device="/dev/spidev${spi_bus}.${chip_select}"
        if [ -e "$spi_device" ]; then
            log_message "Available: $spi_device"
            ((spi_count++))
        fi
    done
done

log_message "Total SPI devices found: $spi_count"