#!/bin/bash

# restore-config.sh - Script to restore build configuration files

set -e

BUILD_DIR="build-beaglebone"
CONF_DIR="$BUILD_DIR/conf"

echo "Restoring Yocto build configuration..."

# Check if we're in the right directory
if [ ! -d "conf-templates" ]; then
    echo "Error: conf-templates directory not found. Please run from project root."
    exit 1
fi

# Create build directory and conf if they don't exist
mkdir -p "$CONF_DIR"

# Copy configuration files
if [ -f "conf-templates/local.conf" ]; then
    cp conf-templates/local.conf "$CONF_DIR/"
    echo "Restored local.conf"
else
    echo "Warning: conf-templates/local.conf not found"
fi

if [ -f "conf-templates/bblayers.conf" ]; then
    cp conf-templates/bblayers.conf "$CONF_DIR/"
    echo "Restored bblayers.conf"
else
    echo "Warning: conf-templates/bblayers.conf not found"
fi

echo "Configuration files restored to $CONF_DIR/"
echo "You can now run: source poky/oe-init-build-env $BUILD_DIR"