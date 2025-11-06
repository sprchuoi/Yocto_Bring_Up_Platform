#!/bin/bash

# setup-build.sh - Script to set up the Yocto build environment

set -e

echo "Setting up Yocto build environment for BeagleBone..."

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "poky" ]; then
    echo "Error: Please run this script from the Yocto_build_custom directory"
    exit 1
fi

# Initialize and update submodules if needed
if [ ! -f "poky/oe-init-build-env" ]; then
    echo "Initializing Git submodules..."
    git submodule update --init --recursive
fi

# Source the Yocto environment
if [ -f "poky/oe-init-build-env" ]; then
    echo "Sourcing Yocto build environment..."
    source poky/oe-init-build-env build-beaglebone
    
    echo ""
    echo "Build environment is ready!"
    echo "You can now run: bitbake core-image-minimal"
    echo ""
    echo "Configuration files:"
    echo "  - conf/local.conf - Main build configuration"
    echo "  - conf/bblayers.conf - Layer configuration"
    echo ""
    echo "Build output will be in:"
    echo "  - tmp/deploy/images/beaglebone-yocto/"
else
    echo "Error: Could not find poky/oe-init-build-env"
    exit 1
fi