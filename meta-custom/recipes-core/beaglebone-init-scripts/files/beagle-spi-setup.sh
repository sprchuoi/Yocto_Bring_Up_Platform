#!/bin/bash
#
# BeagleBone SPI interface setup script
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): BEAGLE-SPI-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up BeagleBone SPI interfaces..."

# SPI device mapping on BeagleBone:
# SPI0: /dev/spidev1.0, /dev/spidev1.1 (Header P9)
# SPI1: /dev/spidev2.0, /dev/spidev2.1 (Header P9)

# Set up SPI device permissions
for spi_bus in {1..2}; do
    for chip_select in {0..1}; do
        spi_device="/dev/spidev${spi_bus}.${chip_select}"
        
        if [ -e "$spi_device" ]; then
            chmod 666 "$spi_device"
            log_message "SPI${spi_bus}.${chip_select} ($spi_device) configured"
            
            # Create convenient symlinks
            ln -sf "$spi_device" "/dev/spi${spi_bus}_${chip_select}" 2>/dev/null || true
        fi
    done
done

# Add user to spi group for SPI access
if id "root" >/dev/null 2>&1; then
    usermod -a -G spi root 2>/dev/null || true
    log_message "Added user 'root' to spi group"
fi

# Create SPI configuration directory
mkdir -p /etc/spi

# Create SPI configuration file
cat > /etc/spi/interfaces <<EOF
# SPI interface configuration for BeagleBone

# SPI0 (mapped as spidev1.x)
# Device: /dev/spidev1.0, /dev/spidev1.1
# Header P9: SCLK=P9.22, MISO=P9.21, MOSI=P9.18, CS0=P9.17, CS1=P9.42

# SPI1 (mapped as spidev2.x)  
# Device: /dev/spidev2.0, /dev/spidev2.1
# Header P9: SCLK=P9.31, MISO=P9.29, MOSI=P9.30, CS0=P9.28, CS1=P9.19

# Usage examples:
# spi-config -d /dev/spidev1.0 -s 1000000
# echo -e "\\x01\\x02\\x03" | spi-pipe -d /dev/spidev1.0
EOF

log_message "BeagleBone SPI setup completed"
log_message "Configuration file: /etc/spi/interfaces"