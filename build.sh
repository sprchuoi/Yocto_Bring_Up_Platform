#!/bin/bash

# build.sh - Advanced Yocto build script with monitoring and options

set -e

# Supported platforms and images
PLATFORMS=("beaglebone" "raspberrypi4" "jetson-nano")
COMMON_IMAGES=("core-image-minimal" "core-image-base" "core-image-full-cmdline")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo "Usage: $0 [PLATFORM] [IMAGE] [OPTIONS]"
    echo ""
    echo "Supported platforms:"
    for platform in "${PLATFORMS[@]}"; do
        echo "  - $platform"
    done
    echo ""
    echo "Common images:"
    for image in "${COMMON_IMAGES[@]}"; do
        echo "  - $image"
    done
    echo ""
    echo "Options:"
    echo "  --clean           Clean build before starting"
    echo "  --continue        Continue interrupted build"
    echo "  --force           Force rebuild even if up-to-date"
    echo "  --verbose         Show verbose output"
    echo "  --dry-run         Show what would be built without building"
    echo "  --parallel=N      Set number of parallel jobs (default: auto)"
    echo "  --sdk             Build SDK after image"
    echo "  --package=PKG     Build specific package only"
    echo ""
    echo "Examples:"
    echo "  $0 raspberrypi4 core-image-minimal"
    echo "  $0 jetson-nano core-image-base --clean"
    echo "  $0 beaglebone core-image-minimal --sdk"
    echo "  $0 raspberrypi4 --package=linux-raspberrypi"
    echo ""
}

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to estimate build time
estimate_build_time() {
    local platform=$1
    local is_clean=$2
    
    if [ "$is_clean" = true ]; then
        case $platform in
            "beaglebone") echo "2-3 hours" ;;
            "raspberrypi4") echo "3-4 hours" ;;
            "jetson-nano") echo "4-6 hours" ;;
        esac
    else
        echo "10-60 minutes (incremental)"
    fi
}

# Function to check disk space
check_disk_space() {
    local build_dir=$1
    local required_gb=40
    
    if [ -d "$build_dir" ]; then
        local available=$(df "$build_dir" | awk 'NR==2 {print int($4/1024/1024)}')
    else
        local available=$(df . | awk 'NR==2 {print int($4/1024/1024)}')
    fi
    
    if [ "$available" -lt "$required_gb" ]; then
        print_status $RED "❌ Warning: Only ${available}GB available. Recommended: ${required_gb}GB+"
        echo "Continue anyway? (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status $GREEN "✅ Disk space: ${available}GB available"
    fi
}

# Function to monitor build progress
monitor_build() {
    local log_file="$1"
    local image="$2"
    
    if [ -f "$log_file" ]; then
        echo ""
        print_status $BLUE "📊 Build Progress Monitor (Ctrl+C to stop monitoring, build continues)"
        echo "Build log: $log_file"
        echo ""
        
        # Show last few lines and follow
        tail -f "$log_file" | while read -r line; do
            # Highlight important messages
            case "$line" in
                *"ERROR"*) print_status $RED "$line" ;;
                *"WARNING"*) print_status $YELLOW "$line" ;;
                *"NOTE: Tasks Summary"*) print_status $GREEN "$line" ;;
                *"Currently"*"running tasks"*) print_status $BLUE "$line" ;;
                *) echo "$line" ;;
            esac
        done
    fi
}

# Parse command line arguments
PLATFORM=""
IMAGE=""
CLEAN_BUILD=false
CONTINUE_BUILD=false
FORCE_BUILD=false
VERBOSE=false
DRY_RUN=false
BUILD_SDK=false
PARALLEL_JOBS=""
PACKAGE_ONLY=""

for arg in "$@"; do
    case $arg in
        --clean)
            CLEAN_BUILD=true
            ;;
        --continue)
            CONTINUE_BUILD=true
            ;;
        --force)
            FORCE_BUILD=true
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --dry-run)
            DRY_RUN=true
            ;;
        --sdk)
            BUILD_SDK=true
            ;;
        --parallel=*)
            PARALLEL_JOBS="${arg#*=}"
            ;;
        --package=*)
            PACKAGE_ONLY="${arg#*=}"
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
            elif [ -z "$IMAGE" ] && [ -z "$PACKAGE_ONLY" ]; then
                IMAGE="$arg"
            else
                echo "Error: Too many arguments"
                usage
                exit 1
            fi
            ;;
    esac
done

# Set defaults
PLATFORM=${PLATFORM:-beaglebone}
if [ -z "$PACKAGE_ONLY" ]; then
    IMAGE=${IMAGE:-core-image-minimal}
fi

# Validate platform
if [[ ! " ${PLATFORMS[@]} " =~ " ${PLATFORM} " ]]; then
    echo "Error: Unsupported platform '$PLATFORM'"
    usage
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "poky/oe-init-build-env" ]; then
    echo "Error: Please run this script from the Yocto project root directory"
    exit 1
fi

BUILD_DIR="build-${PLATFORM}"

print_status $BLUE "🚀 Yocto Build Script for $PLATFORM"
echo "=================================="

# Check disk space
check_disk_space "$BUILD_DIR"

# Estimate build time
if [ "$CLEAN_BUILD" = true ] || [ ! -d "$BUILD_DIR" ]; then
    ESTIMATED_TIME=$(estimate_build_time "$PLATFORM" true)
    print_status $YELLOW "⏱️  Estimated build time: $ESTIMATED_TIME"
else
    ESTIMATED_TIME=$(estimate_build_time "$PLATFORM" false)
    print_status $YELLOW "⏱️  Estimated build time: $ESTIMATED_TIME"
fi

# Clean if requested
if [ "$CLEAN_BUILD" = true ] && [ -d "$BUILD_DIR" ]; then
    print_status $YELLOW "🧹 Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

# Source environment
print_status $BLUE "🔧 Setting up build environment..."
source poky/oe-init-build-env "$BUILD_DIR"

# Copy configuration if needed
if [ ! -f "conf/local.conf" ]; then
    print_status $BLUE "📋 Copying platform configuration..."
    cp "../conf-templates/$PLATFORM/local.conf" conf/
    cp "../conf-templates/$PLATFORM/bblayers.conf" conf/
fi

# Set parallel jobs if specified
if [ -n "$PARALLEL_JOBS" ]; then
    print_status $BLUE "⚡ Setting parallel jobs to $PARALLEL_JOBS"
    sed -i "s/PARALLEL_MAKE ?= .*/PARALLEL_MAKE ?= \"-j $PARALLEL_JOBS\"/" conf/local.conf
    sed -i "s/BB_NUMBER_THREADS ?= .*/BB_NUMBER_THREADS ?= \"$PARALLEL_JOBS\"/" conf/local.conf
fi

# Determine what to build
if [ -n "$PACKAGE_ONLY" ]; then
    BUILD_TARGET="$PACKAGE_ONLY"
    print_status $GREEN "📦 Building package: $PACKAGE_ONLY"
else
    BUILD_TARGET="$IMAGE"
    print_status $GREEN "🖼️  Building image: $IMAGE"
fi

# Show dry run information
if [ "$DRY_RUN" = true ]; then
    print_status $BLUE "🔍 Dry run - showing what would be built:"
    bitbake -n "$BUILD_TARGET"
    exit 0
fi

# Build command construction
BUILD_CMD="bitbake"
if [ "$VERBOSE" = true ]; then
    BUILD_CMD="$BUILD_CMD -v"
fi
if [ "$FORCE_BUILD" = true ]; then
    BUILD_CMD="$BUILD_CMD -f"
fi
if [ "$CONTINUE_BUILD" = true ]; then
    BUILD_CMD="$BUILD_CMD -c compile"
fi

BUILD_CMD="$BUILD_CMD $BUILD_TARGET"

# Start the build
print_status $GREEN "🏗️  Starting build..."
echo "Command: $BUILD_CMD"
echo "Started at: $(date)"
echo ""

# Start build and capture output
BUILD_LOG="bitbake-build-$(date +%Y%m%d-%H%M%S).log"
$BUILD_CMD 2>&1 | tee "$BUILD_LOG"

BUILD_RESULT=${PIPESTATUS[0]}

if [ $BUILD_RESULT -eq 0 ]; then
    print_status $GREEN "✅ Build completed successfully!"
    
    # Build SDK if requested
    if [ "$BUILD_SDK" = true ] && [ -z "$PACKAGE_ONLY" ]; then
        print_status $BLUE "🛠️  Building SDK..."
        bitbake "$IMAGE" -c populate_sdk
    fi
    
    # Show results
    if [ -z "$PACKAGE_ONLY" ]; then
        print_status $BLUE "📁 Build artifacts:"
        MACHINE_DIR=$(find tmp/deploy/images -maxdepth 1 -type d ! -name images | head -1)
        if [ -n "$MACHINE_DIR" ] && [ -d "$MACHINE_DIR" ]; then
            ls -lh "$MACHINE_DIR"/*.wic "$MACHINE_DIR"/*.tar.* 2>/dev/null | head -10
            
            print_status $GREEN "💾 Flash command:"
            echo "sudo dd if=$MACHINE_DIR/[IMAGE].wic of=/dev/sdX bs=1M status=progress"
        fi
    fi
else
    print_status $RED "❌ Build failed!"
    echo "Check the build log: $BUILD_LOG"
    exit 1
fi

echo ""
print_status $GREEN "🎉 All done! Completed at: $(date)"