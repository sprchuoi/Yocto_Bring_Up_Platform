#!/bin/bash

# CLI Core Functions
# Core functionality for the PK Platform CLI

# Color definitions
CLI_RED='\033[0;31m'
CLI_GREEN='\033[0;32m'
CLI_YELLOW='\033[1;33m'
CLI_BLUE='\033[0;34m'
CLI_MAGENTA='\033[0;35m'
CLI_CYAN='\033[0;36m'
CLI_WHITE='\033[0;37m'
CLI_BOLD='\033[1m'
CLI_NC='\033[0m' # No Color

# Status functions
print_success() {
    echo -e "${CLI_GREEN}✓ $1${CLI_NC}"
}

print_error() {
    echo -e "${CLI_RED}✗ $1${CLI_NC}"
}

print_warning() {
    echo -e "${CLI_YELLOW}⚠ $1${CLI_NC}"
}

print_info() {
    echo -e "${CLI_BLUE}ℹ $1${CLI_NC}"
}

print_header() {
    echo -e "${CLI_CYAN}${CLI_BOLD}$1${CLI_NC}"
}

print_subheader() {
    echo -e "${CLI_MAGENTA}$1${CLI_NC}"
}

# Validation functions
validate_platform() {
    local platform="$1"
    local valid_platforms=("beaglebone" "raspberrypi4" "jetson-nano")
    
    for valid in "${valid_platforms[@]}"; do
        if [[ "$platform" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

validate_image() {
    local image="$1"
    local valid_images=("minimal" "base" "full" "core-image-minimal" "core-image-base" "core-image-full-cmdline")
    
    for valid in "${valid_images[@]}"; do
        if [[ "$image" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

# Convert short image names to full names
normalize_image_name() {
    local image="$1"
    
    case "$image" in
        "minimal")
            echo "core-image-minimal"
            ;;
        "base")
            echo "core-image-base"
            ;;
        "full")
            echo "core-image-full-cmdline"
            ;;
        *)
            echo "$image"
            ;;
    esac
}

# Check if we're in the right directory
check_workspace() {
    if [ ! -f "README.md" ] || [ ! -d "poky" ]; then
        print_error "Please run this command from the Yocto_build_custom directory"
        print_info "Expected files: README.md, poky/ directory"
        return 1
    fi
    return 0
}

# Check build prerequisites
check_build_prereqs() {
    local platform="$1"
    local build_dir="build-$platform"
    
    # Check if platform is set up
    if [ ! -d "$build_dir" ]; then
        print_warning "Platform $platform is not set up"
        print_info "Run: pk setup $platform"
        return 1
    fi
    
    # Check if conf files exist
    if [ ! -f "$build_dir/conf/local.conf" ] || [ ! -f "$build_dir/conf/bblayers.conf" ]; then
        print_warning "Platform configuration is incomplete"
        print_info "Run: pk setup $platform"
        return 1
    fi
    
    return 0
}

# Progress bar function
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${CLI_CYAN}$message [%*s%*s] %d%%${CLI_NC}" \
           "$filled" | tr ' ' '█' \
           "$empty" | tr ' ' '░' \
           "$percent"
}

# Spinner function for long operations
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    local message="${2:-Working...}"
    
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${CLI_YELLOW}%s %c${CLI_NC}" "$message" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
}

# Time formatting
format_duration() {
    local duration=$1
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $seconds
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" $minutes $seconds
    else
        printf "%ds" $seconds
    fi
}

# File size formatting
format_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [ $size -gt 1024 ] && [ $unit -lt 4 ]; do
        size=$((size / 1024))
        unit=$((unit + 1))
    done
    
    printf "%d %s" $size "${units[$unit]}"
}

# Logging functions
log_command() {
    local command="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $command" >> "$SCRIPT_DIR/logs/cli.log"
}

log_error() {
    local error="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $error" >> "$SCRIPT_DIR/logs/cli-errors.log"
}

# Create log directory if it doesn't exist
mkdir -p "$SCRIPT_DIR/logs" 2>/dev/null || true

# Environment detection
detect_environment() {
    local env_info=""
    
    # OS detection
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        env_info="Linux"
        if [ -f /etc/wsl.conf ]; then
            env_info="$env_info (WSL)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        env_info="macOS"
    else
        env_info="Unknown"
    fi
    
    echo "$env_info"
}

# System resource check
check_system_resources() {
    local min_disk_gb=50
    local min_ram_gb=4
    
    # Check disk space (in GB)
    local disk_avail=$(df . | tail -1 | awk '{print int($4/1024/1024)}')
    if [ $disk_avail -lt $min_disk_gb ]; then
        print_warning "Low disk space: ${disk_avail}GB (recommended: ${min_disk_gb}GB+)"
    fi
    
    # Check RAM (Linux only)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
        if [ $ram_gb -lt $min_ram_gb ]; then
            print_warning "Low RAM: ${ram_gb}GB (recommended: ${min_ram_gb}GB+)"
        fi
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc 2>/dev/null || echo "unknown")
    if [ "$cpu_cores" != "unknown" ] && [ $cpu_cores -lt 4 ]; then
        print_warning "Few CPU cores: $cpu_cores (recommended: 4+)"
    fi
}