#!/bin/bash

# SD Card Flashing Script for Yocto Images
# Supports bmaptool and manual flashing with partition handling

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'
C_RESET='\033[0m'

# Default values
PLATFORM=""
IMAGE_TYPE="core-image-minimal"
DEVICE=""
USE_BMAP=true

# Print colored message
print_info() {
    echo -e "${C_CYAN}ℹ ${C_RESET}$1"
}

print_success() {
    echo -e "${C_GREEN}✓${C_RESET} $1"
}

print_warning() {
    echo -e "${C_YELLOW}⚠${C_RESET} $1"
}

print_error() {
    echo -e "${C_RED}✗${C_RESET} $1"
}

print_header() {
    echo -e "${C_BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║          SD Card Flashing Tool for Yocto Images           ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${C_RESET}"
}

# Show usage
usage() {
    print_header
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Platform: beaglebone, raspberrypi4, jetson-nano"
    echo "  -d, --device DEVICE        Target device (e.g., /dev/sdb, /dev/mmcblk0)"
    echo "  -i, --image IMAGE          Image type (default: core-image-minimal)"
    echo "  -n, --no-bmap              Don't use bmaptool (manual dd)"
    echo "  -h, --help                 Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 -p beaglebone -d /dev/sdb"
    echo "  $0 -p raspberrypi4 -d /dev/mmcblk0 -i core-image-full-cmdline"
    echo ""
    exit 1
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--platform)
                PLATFORM="$2"
                shift 2
                ;;
            -d|--device)
                DEVICE="$2"
                shift 2
                ;;
            -i|--image)
                IMAGE_TYPE="$2"
                shift 2
                ;;
            -n|--no-bmap)
                USE_BMAP=false
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
}

# Validate platform
validate_platform() {
    case "$PLATFORM" in
        beaglebone|raspberrypi4|jetson-nano)
            return 0
            ;;
        *)
            print_error "Invalid platform: $PLATFORM"
            print_info "Valid platforms: beaglebone, raspberrypi4, jetson-nano"
            exit 1
            ;;
    esac
}

# Get machine name for platform
get_machine_name() {
    case "$PLATFORM" in
        beaglebone)
            echo "beaglebone-yocto"
            ;;
        raspberrypi4)
            echo "raspberrypi4-64"
            ;;
        jetson-nano)
            echo "jetson-nano"
            ;;
    esac
}

# Check if device exists and is a block device
validate_device() {
    if [[ ! -b "$DEVICE" ]]; then
        print_error "Device $DEVICE is not a valid block device"
        exit 1
    fi
    
    # Check if device is mounted
    if mount | grep -q "^$DEVICE"; then
        print_warning "Device $DEVICE has mounted partitions"
        return 1
    fi
    
    return 0
}

# List available block devices
list_devices() {
    print_info "Available block devices:"
    echo ""
    lsblk -d -o NAME,SIZE,TYPE,TRAN,MODEL | grep -E "disk|NAME"
    echo ""
}

# Unmount all partitions on device
unmount_device() {
    local device="$1"
    print_info "Unmounting all partitions on $device..."
    
    # Get all partitions
    local partitions=$(lsblk -ln -o NAME "$device" | tail -n +2)
    
    for part in $partitions; do
        local part_path="/dev/$part"
        if mount | grep -q "^$part_path"; then
            print_info "Unmounting $part_path..."
            sudo umount "$part_path" 2>/dev/null || true
        fi
    done
    
    print_success "All partitions unmounted"
}

# Find image file
find_image() {
    local machine=$(get_machine_name)
    local build_dir="$PROJECT_ROOT/build-$PLATFORM"
    local deploy_dir="$build_dir/tmp/deploy/images/$machine"
    
    if [[ ! -d "$deploy_dir" ]]; then
        print_error "Deploy directory not found: $deploy_dir"
        print_info "Please build the image first using: ./build.sh build $PLATFORM"
        exit 1
    fi
    
    # Look for .wic.bz2 or .wic.gz images
    local image_file=$(find "$deploy_dir" -name "${IMAGE_TYPE}-${machine}.wic.bz2" -o -name "${IMAGE_TYPE}-${machine}.wic.gz" -o -name "${IMAGE_TYPE}-${machine}.wic" | head -n 1)
    
    if [[ -z "$image_file" ]]; then
        print_error "Image file not found in $deploy_dir"
        print_info "Looking for: ${IMAGE_TYPE}-${machine}.wic*"
        echo ""
        print_info "Available images:"
        ls -lh "$deploy_dir"/*.wic* 2>/dev/null || print_warning "No .wic images found"
        exit 1
    fi
    
    echo "$image_file"
}

# Find bmap file
find_bmap() {
    local image_file="$1"
    local bmap_file="${image_file%.bz2}.bmap"
    bmap_file="${bmap_file%.gz}.bmap"
    
    if [[ -f "$bmap_file" ]]; then
        echo "$bmap_file"
    else
        echo ""
    fi
}

# Flash using bmaptool
flash_with_bmap() {
    local image_file="$1"
    local bmap_file="$2"
    local device="$3"
    
    print_info "Flashing with bmaptool..."
    print_info "Image: $(basename $image_file)"
    print_info "Device: $device"
    
    if [[ -z "$bmap_file" ]]; then
        print_warning "No .bmap file found, bmaptool will be slower"
        sudo bmaptool copy "$image_file" "$device"
    else
        print_info "Using bmap: $(basename $bmap_file)"
        sudo bmaptool copy --bmap "$bmap_file" "$image_file" "$device"
    fi
}

# Flash using dd
flash_with_dd() {
    local image_file="$1"
    local device="$2"
    
    print_info "Flashing with dd..."
    print_info "Image: $(basename $image_file)"
    print_info "Device: $device"
    
    # Determine decompression command
    local decompress=""
    if [[ "$image_file" == *.bz2 ]]; then
        decompress="bunzip2 -c"
    elif [[ "$image_file" == *.gz ]]; then
        decompress="gunzip -c"
    else
        decompress="cat"
    fi
    
    print_warning "This may take several minutes..."
    
    # Flash with progress
    $decompress "$image_file" | sudo dd of="$device" bs=4M status=progress conv=fsync
    
    sync
}

# Show partition information
show_partitions() {
    local device="$1"
    
    print_info "Partition layout on $device:"
    echo ""
    sudo fdisk -l "$device"
    echo ""
    lsblk "$device" -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT
    echo ""
}

# Interactive mode
interactive_mode() {
    print_header
    
    # Select platform
    if [[ -z "$PLATFORM" ]]; then
        echo "Select platform:"
        echo "  1) BeagleBone Black/Green"
        echo "  2) Raspberry Pi 4 64-bit"
        echo "  3) NVIDIA Jetson Nano"
        echo ""
        read -p "Enter choice [1-3]: " choice
        
        case $choice in
            1) PLATFORM="beaglebone" ;;
            2) PLATFORM="raspberrypi4" ;;
            3) PLATFORM="jetson-nano" ;;
            *) print_error "Invalid choice"; exit 1 ;;
        esac
    fi
    
    validate_platform
    
    # List and select device
    if [[ -z "$DEVICE" ]]; then
        echo ""
        list_devices
        read -p "Enter device path (e.g., /dev/sdb): " DEVICE
    fi
    
    if [[ -z "$DEVICE" ]]; then
        print_error "No device specified"
        exit 1
    fi
    
    validate_device || true
    
    # Confirm
    echo ""
    print_warning "═══════════════════════════════════════════════════"
    print_warning "  WARNING: ALL DATA ON $DEVICE WILL BE DESTROYED!"
    print_warning "═══════════════════════════════════════════════════"
    echo ""
    print_info "Platform: $PLATFORM"
    print_info "Image: $IMAGE_TYPE"
    print_info "Device: $DEVICE"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_info "Cancelled by user"
        exit 0
    fi
}

# Main function
main() {
    parse_args "$@"
    
    # If no arguments, run interactive mode
    if [[ -z "$PLATFORM" ]] || [[ -z "$DEVICE" ]]; then
        interactive_mode
    else
        print_header
        validate_platform
        validate_device
    fi
    
    # Find image
    print_info "Searching for image..."
    IMAGE_FILE=$(find_image)
    print_success "Found image: $(basename $IMAGE_FILE)"
    
    # Get file size
    IMAGE_SIZE=$(du -h "$IMAGE_FILE" | cut -f1)
    print_info "Image size: $IMAGE_SIZE"
    
    # Unmount device
    unmount_device "$DEVICE"
    
    # Flash image
    echo ""
    if $USE_BMAP && command -v bmaptool &>/dev/null; then
        BMAP_FILE=$(find_bmap "$IMAGE_FILE")
        flash_with_bmap "$IMAGE_FILE" "$BMAP_FILE" "$DEVICE"
    else
        if $USE_BMAP && ! command -v bmaptool &>/dev/null; then
            print_warning "bmaptool not installed, falling back to dd"
            print_info "Install with: sudo apt-get install bmap-tools"
        fi
        flash_with_dd "$IMAGE_FILE" "$DEVICE"
    fi
    
    # Sync and show results
    echo ""
    print_info "Syncing filesystems..."
    sync
    
    sleep 2
    
    print_success "Flashing completed successfully!"
    echo ""
    
    # Show partition info
    show_partitions "$DEVICE"
    
    print_success "SD card is ready! You can safely remove it now."
}

# Run main
main "$@"
