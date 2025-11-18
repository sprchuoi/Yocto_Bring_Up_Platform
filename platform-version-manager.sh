#!/bin/bash

# Platform-specific Hardware Initialization Version Manager
# Handles versioning and patches for BeagleBone and Raspberry Pi 4 configurations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
META_CUSTOM_DIR="$SCRIPT_DIR/meta-custom"

# Version information
BEAGLEBONE_VERSION="1.0.0"
RPI4_VERSION="1.0.0"

echo "=========================================="
echo "Platform Hardware Init Version Manager"
echo "=========================================="

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  status              Show version status of all platforms"
    echo "  version [platform]  Show version of specific platform"
    echo "  update [platform]   Update platform configuration"
    echo "  patch [platform]    Apply patches for platform"
    echo "  info [platform]     Show platform information"
    echo ""
    echo "Platforms:"
    echo "  beaglebone         BeagleBone Black/Green industrial config"
    echo "  rpi4               Raspberry Pi 4 industrial config"
    echo ""
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 version beaglebone"
    echo "  $0 info rpi4"
    echo "  $0 patch beaglebone"
}

show_status() {
    echo "Platform Configuration Status:"
    echo "=============================="
    echo ""
    
    # BeagleBone status
    if [ -d "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts" ]; then
        echo "✓ BeagleBone: v$BEAGLEBONE_VERSION"
        echo "  Recipe: beaglebone-init-scripts.bb"
        echo "  Features: CAN, UART, SPI, WiFi (headless)"
        
        patch_count=$(ls -1 "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/files/"*.patch 2>/dev/null | wc -l)
        echo "  Patches: $patch_count available"
    else
        echo "✗ BeagleBone: Not configured"
    fi
    
    echo ""
    
    # Raspberry Pi 4 status
    if [ -d "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts" ]; then
        echo "✓ Raspberry Pi 4: v$RPI4_VERSION"
        echo "  Recipe: rpi4-init-scripts.bb"
        echo "  Features: SSH, WiFi, Docker, CAN-FD, UART, SPI, Ethernet"
        
        patch_count=$(ls -1 "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/files/"*.patch 2>/dev/null | wc -l)
        echo "  Patches: $patch_count available"
    else
        echo "✗ Raspberry Pi 4: Not configured"
    fi
    
    echo ""
}

show_version() {
    platform="$1"
    
    case "$platform" in
        beaglebone)
            echo "BeagleBone Hardware Init Version: $BEAGLEBONE_VERSION"
            if [ -f "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/beaglebone-init-scripts.bb" ]; then
                echo "Recipe file: beaglebone-init-scripts.bb"
                grep "^PV\|^PR" "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/beaglebone-init-scripts.bb"
            fi
            ;;
        rpi4)
            echo "Raspberry Pi 4 Hardware Init Version: $RPI4_VERSION"
            if [ -f "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/rpi4-init-scripts.bb" ]; then
                echo "Recipe file: rpi4-init-scripts.bb"
                grep "^PV\|^PR" "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/rpi4-init-scripts.bb"
            fi
            ;;
        *)
            echo "Unknown platform: $platform"
            echo "Available platforms: beaglebone, rpi4"
            exit 1
            ;;
    esac
}

show_info() {
    platform="$1"
    
    case "$platform" in
        beaglebone)
            echo "BeagleBone Industrial Configuration"
            echo "==================================="
            echo "Version: $BEAGLEBONE_VERSION"
            echo "Target Machine: beaglebone-yocto"
            echo "Features:"
            echo "  • Headless operation (no UI/X11)"
            echo "  • CAN bus support"
            echo "  • Multiple UART interfaces (ttyO1-5)"
            echo "  • SPI interface support"
            echo "  • WiFi support (USB adapters)"
            echo "  • Industrial IoT tools"
            echo ""
            echo "Hardware Scripts:"
            echo "  • beagle-hardware-init.sh - Main initialization"
            echo "  • beagle-can-setup.sh - CAN interface setup"
            echo "  • beagle-uart-setup.sh - UART configuration"
            echo "  • beagle-spi-setup.sh - SPI configuration"
            echo "  • beagle-wifi-setup.sh - WiFi setup"
            echo ""
            echo "Available Patches:"
            if [ -d "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/files" ]; then
                ls -1 "$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/files/"*.patch 2>/dev/null || echo "  None"
            fi
            ;;
        rpi4)
            echo "Raspberry Pi 4 Industrial Configuration"
            echo "======================================="
            echo "Version: $RPI4_VERSION"
            echo "Target Machine: raspberrypi4-64"
            echo "Features:"
            echo "  • SSH server (port 22)"
            echo "  • WiFi and Bluetooth support"
            echo "  • Docker container platform"
            echo "  • CAN bus with CAN-FD support"
            echo "  • Multiple UART interfaces (ttyAMA1-5)"
            echo "  • Multiple SPI interfaces (6 buses)"
            echo "  • Gigabit Ethernet"
            echo "  • GPIO and I2C access"
            echo ""
            echo "Hardware Scripts:"
            echo "  • rpi4-hardware-init.sh - Main initialization"
            echo "  • rpi4-can-setup.sh - CAN/CAN-FD setup"
            echo "  • rpi4-uart-setup.sh - UART configuration"
            echo "  • rpi4-spi-setup.sh - SPI configuration"
            echo ""
            echo "Available Patches:"
            if [ -d "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/files" ]; then
                ls -1 "$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/files/"*.patch 2>/dev/null || echo "  None"
            fi
            ;;
        *)
            echo "Unknown platform: $platform"
            echo "Available platforms: beaglebone, rpi4"
            exit 1
            ;;
    esac
    echo ""
}

apply_patches() {
    platform="$1"
    
    case "$platform" in
        beaglebone)
            patch_dir="$META_CUSTOM_DIR/recipes-core/beaglebone-init-scripts/files"
            echo "Applying patches for BeagleBone..."
            ;;
        rpi4)
            patch_dir="$META_CUSTOM_DIR/recipes-core/rpi4-init-scripts/files"
            echo "Applying patches for Raspberry Pi 4..."
            ;;
        *)
            echo "Unknown platform: $platform"
            exit 1
            ;;
    esac
    
    if [ -d "$patch_dir" ]; then
        patch_count=$(ls -1 "$patch_dir"/*.patch 2>/dev/null | wc -l)
        if [ "$patch_count" -gt 0 ]; then
            echo "Found $patch_count patch(es):"
            ls -1 "$patch_dir"/*.patch 2>/dev/null | xargs -n 1 basename
            echo ""
            echo "Patches are automatically applied during build process."
            echo "No manual application needed."
        else
            echo "No patches found for $platform"
        fi
    else
        echo "Patch directory not found: $patch_dir"
    fi
}

# Main command processing
case "${1:-status}" in
    status)
        show_status
        ;;
    version)
        if [ -z "$2" ]; then
            echo "Please specify a platform: beaglebone or rpi4"
            exit 1
        fi
        show_version "$2"
        ;;
    info)
        if [ -z "$2" ]; then
            echo "Please specify a platform: beaglebone or rpi4"
            exit 1
        fi
        show_info "$2"
        ;;
    patch)
        if [ -z "$2" ]; then
            echo "Please specify a platform: beaglebone or rpi4"
            exit 1
        fi
        apply_patches "$2"
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac