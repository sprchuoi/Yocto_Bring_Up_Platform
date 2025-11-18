#!/bin/bash
#
# Raspberry Pi 4 UART interface setup script
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): RPI4-UART-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up Raspberry Pi 4 UART interfaces..."

# UART device mapping on Raspberry Pi 4:
# /dev/ttyAMA0 - Primary UART (GPIO 14/15) - usually Bluetooth
# /dev/serial0 - Primary UART alias
# /dev/serial1 - Secondary UART alias  
# /dev/ttyAMA1 - UART1 (GPIO 14/15) when overlay enabled
# /dev/ttyAMA2 - UART2 (GPIO 0/1) when overlay enabled
# /dev/ttyAMA3 - UART3 (GPIO 4/5) when overlay enabled
# /dev/ttyAMA4 - UART4 (GPIO 8/9) when overlay enabled
# /dev/ttyAMA5 - UART5 (GPIO 12/13) when overlay enabled

# Configure primary UART (usually /dev/serial0)
if [ -e /dev/serial0 ]; then
    # Set UART parameters: 115200 baud, 8N1
    stty -F /dev/serial0 115200 cs8 -cstopb -parenb raw -echo
    log_message "Primary UART (/dev/serial0) configured: 115200 8N1"
else
    log_message "Primary UART (/dev/serial0) not available"
fi

# Configure secondary UART if available
if [ -e /dev/serial1 ]; then
    stty -F /dev/serial1 115200 cs8 -cstopb -parenb raw -echo
    log_message "Secondary UART (/dev/serial1) configured: 115200 8N1"
else
    log_message "Secondary UART (/dev/serial1) not available"
fi

# Configure additional UARTs (UART1-5)
for uart_num in {1..5}; do
    uart_device="/dev/ttyAMA${uart_num}"
    
    if [ -e "$uart_device" ]; then
        # Configure UART: 115200 baud, 8N1, no flow control
        stty -F "$uart_device" 115200 cs8 -cstopb -parenb raw -echo -crtscts
        chmod 666 "$uart_device"
        log_message "UART${uart_num} ($uart_device) configured: 115200 8N1"
        
        # Create convenient symlinks
        ln -sf "$uart_device" "/dev/uart${uart_num}" 2>/dev/null || true
        
    else
        log_message "UART${uart_num} ($uart_device) not available - check device tree overlays"
    fi
done

# Set up UART permissions for user access
chmod 666 /dev/tty* 2>/dev/null || true

# Add user to dialout group for UART access (if user exists)
if id "pi" >/dev/null 2>&1; then
    usermod -a -G dialout pi
    log_message "Added user 'pi' to dialout group"
fi

if id "root" >/dev/null 2>&1; then
    usermod -a -G dialout root
    log_message "Added user 'root' to dialout group"
fi

# Create UART configuration directory
mkdir -p /etc/uart

# Create UART configuration file with GPIO mapping
cat > /etc/uart/interfaces <<EOF
# UART interface configuration for Raspberry Pi 4
# This file contains GPIO pin mappings and settings

# Primary UART (usually for console/Bluetooth)
# Device: /dev/serial0 (/dev/ttyAMA0)
# GPIO: 14 (TX), 15 (RX)
# Default: 115200 8N1

# UART1 - Additional UART on GPIO 14/15 (alt function)
# Device: /dev/ttyAMA1 
# GPIO: 14 (TX), 15 (RX)
# Overlay: uart1

# UART2 - Additional UART on GPIO 0/1  
# Device: /dev/ttyAMA2
# GPIO: 0 (TX), 1 (RX) 
# Overlay: uart2

# UART3 - Additional UART on GPIO 4/5
# Device: /dev/ttyAMA3
# GPIO: 4 (TX), 5 (RX)
# Overlay: uart3

# UART4 - Additional UART on GPIO 8/9
# Device: /dev/ttyAMA4  
# GPIO: 8 (TX), 9 (RX)
# Overlay: uart4

# UART5 - Additional UART on GPIO 12/13
# Device: /dev/ttyAMA5
# GPIO: 12 (TX), 13 (RX) 
# Overlay: uart5

# Usage examples:
# Send data: echo "Hello" > /dev/ttyAMA1
# Read data: cat /dev/ttyAMA1
# Configure: stty -F /dev/ttyAMA1 9600 cs8 -cstopb -parenb
# Test loopback: minicom -D /dev/ttyAMA1
EOF

# Create UART test script
cat > /usr/local/bin/uart-test <<'EOF'
#!/bin/bash
# UART testing utility for Raspberry Pi 4

if [ $# -lt 1 ]; then
    echo "Usage: $0 <uart_device> [baudrate]"
    echo "Example: $0 /dev/ttyAMA1 115200"
    echo ""
    echo "Available UART devices:"
    ls -la /dev/ttyAMA* 2>/dev/null || echo "  No additional UARTs found"
    ls -la /dev/serial* 2>/dev/null || echo "  No serial devices found"
    exit 1
fi

UART_DEV="$1"
BAUD_RATE="${2:-115200}"

if [ ! -e "$UART_DEV" ]; then
    echo "Error: Device $UART_DEV not found"
    exit 1
fi

echo "Testing UART device: $UART_DEV at $BAUD_RATE baud"
echo "Press Ctrl+C to exit"

# Configure UART
stty -F "$UART_DEV" "$BAUD_RATE" cs8 -cstopb -parenb raw -echo

# Send test message
echo "UART Test - $(date)" > "$UART_DEV"

# Listen for incoming data
cat "$UART_DEV"
EOF

chmod +x /usr/local/bin/uart-test

log_message "Created UART test utility: /usr/local/bin/uart-test"
log_message "Raspberry Pi 4 UART setup completed"
log_message "Configuration file: /etc/uart/interfaces"
log_message "Available tools: minicom, picocom, uart-test"