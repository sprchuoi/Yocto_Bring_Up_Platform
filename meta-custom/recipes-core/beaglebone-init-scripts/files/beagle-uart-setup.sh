#!/bin/bash
#
# BeagleBone UART interface setup script  
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): BEAGLE-UART-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up BeagleBone UART interfaces..."

# UART device mapping on BeagleBone:
# /dev/ttyO0 - Debug UART (usually console)
# /dev/ttyO1 - UART1 
# /dev/ttyO2 - UART2
# /dev/ttyO3 - UART3 
# /dev/ttyO4 - UART4
# /dev/ttyO5 - UART5

# Configure available UART interfaces
for uart_num in {1..5}; do
    uart_device="/dev/ttyO${uart_num}"
    
    if [ -e "$uart_device" ]; then
        # Configure UART: 115200 baud, 8N1, no flow control
        stty -F "$uart_device" 115200 cs8 -cstopb -parenb raw -echo -crtscts
        chmod 666 "$uart_device"
        log_message "UART${uart_num} ($uart_device) configured: 115200 8N1"
        
        # Create convenient symlinks
        ln -sf "$uart_device" "/dev/uart${uart_num}" 2>/dev/null || true
    else
        log_message "UART${uart_num} ($uart_device) not available"
    fi
done

# Set up UART permissions for user access
chmod 666 /dev/tty* 2>/dev/null || true

# Add user to dialout group for UART access
if id "root" >/dev/null 2>&1; then
    usermod -a -G dialout root 2>/dev/null || true
    log_message "Added user 'root' to dialout group"
fi

# Create UART configuration directory
mkdir -p /etc/uart

# Create UART configuration file
cat > /etc/uart/interfaces <<EOF
# UART interface configuration for BeagleBone

# UART0 - Debug console (usually reserved)
# Device: /dev/ttyO0

# UART1 - General purpose UART
# Device: /dev/ttyO1
# Header: P9.24 (TX), P9.26 (RX)

# UART2 - General purpose UART  
# Device: /dev/ttyO2
# Header: P9.21 (TX), P9.22 (RX)

# UART3 - General purpose UART
# Device: /dev/ttyO3
# Header: P9.42 (TX), P8.36 (RX)

# UART4 - General purpose UART
# Device: /dev/ttyO4  
# Header: P9.11 (TX), P9.13 (RX)

# UART5 - General purpose UART
# Device: /dev/ttyO5
# Header: P8.37 (TX), P8.38 (RX)

# Usage examples:
# echo "Hello" > /dev/ttyO1
# cat /dev/ttyO1
# minicom -D /dev/ttyO1
EOF

log_message "BeagleBone UART setup completed"
log_message "Configuration file: /etc/uart/interfaces"