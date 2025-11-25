#!/bin/bash

# setup-build.sh - Script to set up the Yocto build environment and optionally start building

set -e

# Source PK Logo Class
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pk-logo-class.sh"

# Supported platforms
PLATFORMS=("beaglebone" "raspberrypi4" "jetson-nano")

# Default image to build
DEFAULT_IMAGE="core-image-minimal"

# Function to display usage
usage() {
    echo "Usage: $0 [PLATFORM] [--build|--build=IMAGE] [--clean]"
    echo ""
    echo "Supported platforms:"
    for platform in "${PLATFORMS[@]}"; do
        echo "  - $platform"
    done
    echo ""
    echo "Options:"
    echo "  --build           Start building core-image-minimal after setup"
    echo "  --build=IMAGE     Start building specified image after setup"
    echo "  --clean           Clean build directory before setup"
    echo ""
    echo "Examples:"
    echo "  $0 raspberrypi4                    # Setup only"
    echo "  $0 raspberrypi4 --build            # Setup and build core-image-minimal"
    echo "  $0 jetson-nano --build=core-image-base # Setup and build specific image"
    echo "  $0 beaglebone --clean --build      # Clean, setup and build"
    echo ""
    echo "If no platform is specified, beaglebone will be used as default."
}

# Parse command line arguments
PLATFORM=""
BUILD_IMAGE=""
CLEAN_BUILD=false
START_BUILD=false

for arg in "$@"; do
    case $arg in
        --build)
            START_BUILD=true
            BUILD_IMAGE="$DEFAULT_IMAGE"
            ;;
        --build=*)
            START_BUILD=true
            BUILD_IMAGE="${arg#*=}"
            ;;
        --clean)
            CLEAN_BUILD=true
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $arg"
            usage
            exit 1
            ;;
        *)
            if [ -z "$PLATFORM" ]; then
                PLATFORM="$arg"
            else
                echo "Error: Multiple platforms specified"
                usage
                exit 1
            fi
            ;;
    esac
done

# Set default platform if not specified
PLATFORM=${PLATFORM:-beaglebone}

# Validate platform
if [[ ! " ${PLATFORMS[@]} " =~ " ${PLATFORM} " ]]; then
    echo "Error: Unsupported platform '$PLATFORM'"
    usage
    exit 1
fi

# Display PK Logo
pk_logo_show "popup" "gradient" "Platform Kit" "Yocto Build Setup"

echo "Setting up Yocto build environment for $PLATFORM..."
if [ "$START_BUILD" = true ]; then
    echo "Build will start automatically after setup with image: $BUILD_IMAGE"
fi
if [ "$CLEAN_BUILD" = true ]; then
    echo "Clean build requested - will remove existing build directory"
fi

# Save the project root directory (before Yocto changes it)
PROJECT_ROOT="$(pwd)"

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/README.md" ] || [ ! -d "$PROJECT_ROOT/poky" ]; then
    echo "Error: Please run this script from the Yocto_build_custom directory"
    exit 1
fi

# Set build directory name
BUILD_DIR="build-${PLATFORM}"

# Clean build directory if requested
if [ "$CLEAN_BUILD" = true ] && [ -d "$PROJECT_ROOT/$BUILD_DIR" ]; then
    echo "Cleaning existing build directory: $BUILD_DIR"
    rm -rf "$PROJECT_ROOT/$BUILD_DIR"
fi

# Initialize and update submodules if needed
if [ ! -f "$PROJECT_ROOT/poky/oe-init-build-env" ]; then
    echo "Initializing Git submodules..."
    cd "$PROJECT_ROOT"
    git submodule update --init --recursive
fi

# Source the Yocto environment
if [ -f "$PROJECT_ROOT/poky/oe-init-build-env" ]; then
    echo "Sourcing Yocto build environment..."
    cd "$PROJECT_ROOT"
    source poky/oe-init-build-env "$BUILD_DIR"
    
    # Copy platform-specific configuration if it doesn't exist
    if [ ! -f "conf/local.conf" ] && [ -f "$PROJECT_ROOT/conf-templates/$PLATFORM/local.conf" ]; then
        echo "Copying $PLATFORM configuration files..."
        cp "$PROJECT_ROOT/conf-templates/$PLATFORM/local.conf" conf/
        cp "$PROJECT_ROOT/conf-templates/$PLATFORM/bblayers.conf" conf/
    fi
    
    echo ""
    echo "Build environment is ready for $PLATFORM!"
    
    # Platform-specific information
    case $PLATFORM in
        "beaglebone")
            echo "Target: BeagleBone (ARM Cortex-A8)"
            echo "Machine: beaglebone-yocto"
            echo "Build output: tmp/deploy/images/beaglebone-yocto/"
            ;;
        "raspberrypi4")
            echo "Target: Raspberry Pi 4 (ARM Cortex-A72 64-bit)"
            echo "Machine: raspberrypi4-64"
            echo "Build output: tmp/deploy/images/raspberrypi4-64/"
            ;;
        "jetson-nano")
            echo "Target: NVIDIA Jetson Nano (ARM Cortex-A57)"
            echo "Machine: jetson-nano-devkit"
            echo "Build output: tmp/deploy/images/jetson-nano-devkit/"
            ;;
    esac
    
    if [ "$START_BUILD" = true ]; then
        echo ""
        echo "========================================="
        echo "Starting build for $BUILD_IMAGE..."
        echo "========================================="
        echo "This may take several hours on first build."
        echo "You can monitor progress or cancel with Ctrl+C"
        echo ""
        
        # Start the build
        bitbake "$BUILD_IMAGE"
        
        # Check if build was successful
        if [ $? -eq 0 ]; then
            echo ""
            echo "========================================="
            echo "✅ Build completed successfully!"
            echo "========================================="
            echo "Images available in: tmp/deploy/images/"
            
            # List the generated images
            MACHINE_DIR=$(find tmp/deploy/images -maxdepth 1 -type d ! -name images | head -1)
            if [ -n "$MACHINE_DIR" ] && [ -d "$MACHINE_DIR" ]; then
                echo ""
                echo "Generated files:"
                ls -lh "$MACHINE_DIR"/*.wic "$MACHINE_DIR"/*.tar.* 2>/dev/null || true
            fi
        else
            echo ""
            echo "❌ Build failed. Check the logs above for details."
            exit 1
        fi
    else
        echo ""
        echo "Setup complete! To start building, run:"
        echo "  bitbake $DEFAULT_IMAGE"
        echo ""
        echo "Other available images:"
        echo "  - core-image-minimal      # Basic system"
        echo "  - core-image-base         # With package management"
        echo "  - core-image-full-cmdline # Full command line system"
        echo ""
        echo "To rebuild with automatic build next time:"
        echo "  ./setup-build.sh $PLATFORM --build"
    fi
else
    echo "Error: Could not find poky/oe-init-build-env"
    exit 1
fi