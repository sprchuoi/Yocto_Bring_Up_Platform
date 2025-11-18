#!/bin/bash
#
# BeagleBone WiFi setup script
#

LOG_FILE="/var/log/hardware-init.log"

log_message() {
    echo "$(date): BEAGLE-WIFI-SETUP: $1" | tee -a "$LOG_FILE"
}

log_message "Setting up BeagleBone WiFi..."

# Check for USB WiFi adapters
USB_WIFI_FOUND=false

for interface in wlan0 wlan1 wlp*; do
    if ip link show "$interface" >/dev/null 2>&1; then
        log_message "WiFi interface found: $interface"
        USB_WIFI_FOUND=true
        
        # Configure WiFi interface
        ip link set "$interface" up
        log_message "WiFi interface $interface brought up"
    fi
done

if [ "$USB_WIFI_FOUND" = false ]; then
    log_message "No WiFi interfaces found. Connect USB WiFi adapter."
    return 0
fi

# Create wpa_supplicant configuration if not exists
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
#    key_mgmt=WPA-PSK
#}
EOF
    log_message "Created default wpa_supplicant configuration"
fi

# Enable wpa_supplicant service
if systemctl list-unit-files | grep -q wpa_supplicant.service; then
    systemctl enable wpa_supplicant.service
    log_message "Enabled wpa_supplicant service"
fi

log_message "BeagleBone WiFi setup completed"
log_message "Configure networks in /etc/wpa_supplicant/wpa_supplicant.conf"