# Platform-Specific Hardware Initialization

This document describes the separated platform-specific hardware initialization configurations for BeagleBone and Raspberry Pi 4.

## Overview

The meta-custom layer has been restructured to support platform-specific configurations with versioning and patch management:

```
meta-custom/
├── recipes-core/
│   ├── beaglebone-init-scripts/
│   │   ├── beaglebone-init-scripts.bb          # BeagleBone recipe
│   │   └── files/
│   │       ├── beagle-hardware-init.sh         # Main init script
│   │       ├── beagle-can-setup.sh             # CAN configuration
│   │       ├── beagle-uart-setup.sh            # UART setup
│   │       ├── beagle-spi-setup.sh             # SPI setup
│   │       ├── beagle-wifi-setup.sh            # WiFi setup
│   │       ├── beagle-hardware-init.service    # Systemd service
│   │       └── beagle-can-fd.patch             # CAN-FD support patch
│   └── rpi4-init-scripts/
│       ├── rpi4-init-scripts.bb                # Raspberry Pi 4 recipe
│       └── files/
│           ├── rpi4-hardware-init.sh           # Main init script
│           ├── rpi4-can-setup.sh               # CAN/CAN-FD setup
│           ├── rpi4-uart-setup.sh              # UART configuration
│           ├── rpi4-spi-setup.sh               # SPI configuration
│           ├── rpi4-hardware-init.service      # Systemd service
│           ├── rpi4-can-fd-support.patch       # Advanced CAN-FD patch
│           └── rpi4-docker-optimization.patch  # Docker optimization patch
```

## Platform Configurations

### BeagleBone Industrial Configuration (v1.0.0)

**Target Machine:** `beaglebone-yocto`

**Features:**
- Headless operation (no UI/X11)
- CAN bus support
- Multiple UART interfaces (ttyO1-5)
- SPI interface support
- WiFi support (USB adapters)
- Industrial IoT tools

**Recipe:** `beaglebone-init-scripts.bb`
- Compatible with BeagleBone machines only
- Versioned with PV/PR support
- Includes CAN-FD patch

**Scripts:**
- `beagle-hardware-init.sh` - Main system configuration
- `beagle-can-setup.sh` - CAN interface setup with fallback
- `beagle-uart-setup.sh` - UART configuration (ttyO1-5)
- `beagle-spi-setup.sh` - SPI setup (spidev1.x, spidev2.x)
- `beagle-wifi-setup.sh` - USB WiFi adapter support

### Raspberry Pi 4 Industrial Configuration (v1.0.0)

**Target Machine:** `raspberrypi4-64`

**Features:**
- SSH server (port 22)
- WiFi and Bluetooth support
- Docker container platform
- CAN bus with CAN-FD support
- Multiple UART interfaces (ttyAMA1-5)
- Multiple SPI interfaces (6 buses)
- Gigabit Ethernet
- GPIO and I2C access

**Recipe:** `rpi4-init-scripts.bb`
- Compatible with Raspberry Pi 4 64-bit only
- Versioned with PV/PR support
- Includes CAN-FD and Docker optimization patches

**Scripts:**
- `rpi4-hardware-init.sh` - Complete system initialization
- `rpi4-can-setup.sh` - Advanced CAN/CAN-FD setup with hardware detection
- `rpi4-uart-setup.sh` - Multi-UART configuration
- `rpi4-spi-setup.sh` - 6-bus SPI support with testing utilities

## Version Management

Use the `platform-version-manager.sh` script to manage configurations:

### Commands

```bash
# Show status of all platforms
./platform-version-manager.sh status

# Show version of specific platform
./platform-version-manager.sh version beaglebone
./platform-version-manager.sh version rpi4

# Show detailed platform information
./platform-version-manager.sh info beaglebone
./platform-version-manager.sh info rpi4

# Show available patches
./platform-version-manager.sh patch beaglebone
./platform-version-manager.sh patch rpi4
```

## Patch Management

### BeagleBone Patches

1. **beagle-can-fd.patch** - Adds CAN-FD support with automatic fallback to classic CAN

### Raspberry Pi 4 Patches

1. **rpi4-can-fd-support.patch** - Advanced CAN-FD support with hardware detection
2. **rpi4-docker-optimization.patch** - Docker performance optimization for ARM64

## Configuration Usage

### BeagleBone Build

Update `conf-templates/beaglebone/local.conf`:
```
IMAGE_INSTALL:append = " beaglebone-init-scripts"
```

### Raspberry Pi 4 Build

Update `conf-templates/raspberrypi4/local.conf`:
```
IMAGE_INSTALL:append = " rpi4-init-scripts"
```

## Runtime Utilities

### BeagleBone
- `beagle-system-info` - System diagnostics and status

### Raspberry Pi 4
- `rpi4-system-info` - Comprehensive system information
- `uart-test` - UART interface testing
- `spi-test` - SPI interface testing
- `spi-speed-test` - SPI performance benchmarking

## Configuration Files

### BeagleBone
- `/etc/beaglebone/version` - Configuration version info
- `/etc/can/interfaces` - CAN bus settings
- `/etc/uart/interfaces` - UART pin mappings
- `/etc/spi/interfaces` - SPI pin mappings
- `/etc/wpa_supplicant/wpa_supplicant.conf` - WiFi settings

### Raspberry Pi 4
- `/etc/rpi4/version` - Configuration version info  
- `/etc/can/interfaces` - CAN/CAN-FD settings
- `/etc/uart/interfaces` - UART pin mappings
- `/etc/spi/interfaces` - SPI pin mappings
- `/etc/wpa_supplicant/wpa_supplicant.conf` - WiFi settings
- `/etc/docker/daemon.json` - Docker optimization settings

## Building

```bash
# Build BeagleBone industrial image
./setup-build.sh --platform beaglebone
./build.sh --platform beaglebone

# Build Raspberry Pi 4 industrial image
./setup-build.sh --platform raspberrypi4
./build.sh --platform raspberrypi4
```

## Version History

### v1.0.0 (Initial Release)
- Separated platform-specific configurations
- Added versioning and patch support
- Implemented CAN-FD support for both platforms
- Added Docker optimization for Raspberry Pi 4
- Created platform version manager