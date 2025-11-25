#!/bin/bash

# build.sh - PK Platform Interactive Development Tool
# Modern CLI tool with interactive menus and terminal UI

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source dependencies
source "$SCRIPT_DIR/scripts/pk-logo-class.sh"
source "$SCRIPT_DIR/scripts/cli-core.sh"

# Terminal UI Colors and Formatting
declare -A UI_COLORS=(
    [RESET]='\033[0m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [UNDERLINE]='\033[4m'
    [BLINK]='\033[5m'
    [REVERSE]='\033[7m'
    
    # Colors
    [BLACK]='\033[30m'
    [RED]='\033[31m'
    [GREEN]='\033[32m'
    [YELLOW]='\033[33m'
    [BLUE]='\033[34m'
    [MAGENTA]='\033[35m'
    [CYAN]='\033[36m'
    [WHITE]='\033[37m'
    
    # Bright colors
    [BRIGHT_RED]='\033[91m'
    [BRIGHT_GREEN]='\033[92m'
    [BRIGHT_YELLOW]='\033[93m'
    [BRIGHT_BLUE]='\033[94m'
    [BRIGHT_MAGENTA]='\033[95m'
    [BRIGHT_CYAN]='\033[96m'
    [BRIGHT_WHITE]='\033[97m'
)

# Unicode symbols
declare -A SYMBOLS=(
    [ARROW_RIGHT]="▶"
    [ARROW_LEFT]="◀"
    [BULLET]="●"
    [CHECK]="✓"
    [CROSS]="✗"
    [STAR]="★"
    [DIAMOND]="◆"
    [CIRCLE]="○"
    [SQUARE]="■"
    [TRIANGLE]="▲"
    [WARNING]="⚠"
    [INFO]="ℹ"
    [GEAR]="⚙"
    [ROCKET]="🚀"
    [WRENCH]="🔧"
    [HAMMER]="🔨"
    [FOLDER]="📁"
    [FILE]="📄"
    [COMPUTER]="💻"
    [CHIP]="🔲"
)

# Terminal control functions
hide_cursor() { printf '\033[?25l'; }
show_cursor() { printf '\033[?25h'; }
clear_screen() { printf '\033[2J\033[H'; }
clear_line() { printf '\033[2K\r'; }
move_cursor() { printf '\033[%d;%dH' "$1" "$2"; }

# Get terminal dimensions
get_terminal_size() {
    local size
    size=$(stty size 2>/dev/null || echo "24 80")
    TERM_ROWS=${size% *}
    TERM_COLS=${size#* }
}

# Print centered text
print_centered() {
    local text="$1"
    local color="${2:-${UI_COLORS[RESET]}}"
    local padding=$(((TERM_COLS - ${#text}) / 2))
    printf "%*s%b%s%b\n" $padding "" "$color" "$text" "${UI_COLORS[RESET]}"
}

# Print header with border
print_header() {
    local title="$1"
    local color="${2:-${UI_COLORS[CYAN]}}"
    local width=$((TERM_COLS - 4))
    local border=$(printf "%*s" $width "" | tr ' ' '═')
    
    echo ""
    printf "%b╔%s╗%b\n" "$color" "$border" "${UI_COLORS[RESET]}"
    printf "%b║%b" "$color" "${UI_COLORS[RESET]}"
    print_centered "$title" "${UI_COLORS[BOLD]}${UI_COLORS[WHITE]}"
    printf "%b║%b\n" "$color" "${UI_COLORS[RESET]}"
    printf "%b╚%s╝%b\n" "$color" "$border" "${UI_COLORS[RESET]}"
    echo ""
}

# Print menu option
print_menu_option() {
    local number="$1"
    local title="$2"
    local description="$3"
    local selected="${4:-false}"
    local color="${UI_COLORS[CYAN]}"
    local symbol="${SYMBOLS[BULLET]}"
    
    if [[ "$selected" == "true" ]]; then
        color="${UI_COLORS[BRIGHT_YELLOW]}"
        symbol="${SYMBOLS[ARROW_RIGHT]}"
    fi
    
    printf "  %b%s %02d%b │ %b%s%b\n" \
        "$color" "$symbol" "$number" "${UI_COLORS[RESET]}" \
        "${UI_COLORS[BOLD]}${UI_COLORS[WHITE]}" "$title" "${UI_COLORS[RESET]}"
    
    if [[ -n "$description" ]]; then
        printf "      │ %b%s%b\n" \
            "${UI_COLORS[DIM]}${UI_COLORS[WHITE]}" "$description" "${UI_COLORS[RESET]}"
    fi
    echo ""
}

# Print status line
print_status() {
    local message="$1"
    local type="${2:-info}"
    local symbol=""
    local color=""
    
    case "$type" in
        "success") symbol="${SYMBOLS[CHECK]}"; color="${UI_COLORS[GREEN]}" ;;
        "error") symbol="${SYMBOLS[CROSS]}"; color="${UI_COLORS[RED]}" ;;
        "warning") symbol="${SYMBOLS[WARNING]}"; color="${UI_COLORS[YELLOW]}" ;;
        "info") symbol="${SYMBOLS[INFO]}"; color="${UI_COLORS[BLUE]}" ;;
        *) symbol="${SYMBOLS[BULLET]}"; color="${UI_COLORS[WHITE]}" ;;
    esac
    
    printf "%b%s %s%b\n" "$color" "$symbol" "$message" "${UI_COLORS[RESET]}"
}

# Function to check if pk CLI is available
check_pk_cli() {
    if [ ! -f "$SCRIPT_DIR/scripts/pk-cli-original.sh" ]; then
        print_status "PK CLI not found at $SCRIPT_DIR/scripts/pk-cli-original.sh" "error"
        print_status "Make sure you're running this from the project root directory." "info"
        exit 1
    fi
    
    if [ ! -x "$SCRIPT_DIR/scripts/pk-cli-original.sh" ]; then
        print_status "Making PK CLI executable..." "info"
        chmod +x "$SCRIPT_DIR/scripts/pk-cli-original.sh"
    fi
}

# Interactive menu selection
show_interactive_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local key=""
    
    hide_cursor
    
    while true; do
        clear_screen
        print_header "$title" "${UI_COLORS[BRIGHT_BLUE]}"
        
        for i in "${!options[@]}"; do
            local option_data=(${options[$i]//:/ })
            local option_title="${option_data[0]}"
            local option_desc="${option_data[1]:-}"
            local is_selected=false
            
            [[ $i -eq $selected ]] && is_selected=true
            print_menu_option $((i + 1)) "$option_title" "$option_desc" "$is_selected"
        done
        
        echo ""
        print_status "Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit" "info"
        
        # Read key input
        read -rsn1 key
        case "$key" in
            $'\033')  # Arrow keys
                read -rsn1 key
                if [[ "$key" == "[" ]]; then
                    read -rsn1 key
                    case "$key" in
                        "A") [[ $selected -gt 0 ]] && ((selected--)) ;;  # Up
                        "B") [[ $selected -lt $((${#options[@]} - 1)) ]] && ((selected++)) ;;  # Down
                    esac
                fi
                ;;
            "") # Enter
                show_cursor
                return $selected
                ;;
            "q"|"Q")
                show_cursor
                return 255
                ;;
        esac
    done
}

# Platform selection menu
show_platform_menu() {
    local platforms=(
        "beaglebone:BeagleBone Black/Green - Industrial IoT with CAN, UART, SPI"
        "raspberrypi4:Raspberry Pi 4 64-bit - Edge computing with Docker, WiFi, CAN-FD" 
        "jetson-nano:NVIDIA Jetson Nano - AI/ML workloads with GPU acceleration"
    )
    
    show_interactive_menu "Select Target Platform" "${platforms[@]}"
    local choice=$?
    
    case $choice in
        0) echo "beaglebone" ;;
        1) echo "raspberrypi4" ;;
        2) echo "jetson-nano" ;;
        *) echo "" ;;
    esac
}

# Main action menu
show_main_menu() {
    local actions=(
        "build:Build Platform Image"
        "setup:Setup Build Environment"
        "config:Configuration Management"
        "update:Update Config from Templates"
        "status:Show System Status"
        "clean:Clean Build Artifacts"
    )
    
    show_interactive_menu "PK Platform Development Tool" "${actions[@]}"
    return $?
}

# Live command output display
show_live_output() {
    local command="$1"
    local title="$2"
    
    clear_screen
    print_header "$title" "${UI_COLORS[GREEN]}"
    
    echo ""
    print_status "Executing: $command" "info"
    echo ""
    
    # Execute command and show output
    eval "$command"
    local exit_code=$?
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        print_status "Command completed successfully" "success"
    else
        print_status "Command failed with exit code $exit_code" "error"
    fi
    print_status "Press Enter to continue..." "info"
    read -r
}

# Interactive mode
run_interactive_mode() {
    get_terminal_size
    
    while true; do
        # Show main menu
        show_main_menu
        local action=$?
        
        case $action in
            0) # Build
                local platform
                platform=$(show_platform_menu)
                [[ -z "$platform" ]] && continue
                show_live_output "$SCRIPT_DIR/scripts/pk-cli-original.sh build '$platform'" "Building Image for $platform"
                ;;
            1) # Setup
                local platform
                platform=$(show_platform_menu)
                [[ -z "$platform" ]] && continue
                show_live_output "$SCRIPT_DIR/scripts/pk-cli-original.sh setup '$platform'" "Setting up $platform Environment"
                ;;
            2) # Platform
                show_live_output "$SCRIPT_DIR/scripts/pk-cli-original.sh platform list" "Platform Management"
                ;;
            3) # Config
                show_live_output "$SCRIPT_DIR/scripts/pk-cli-original.sh config list" "Configuration Management"
                ;;
            4) # Update
                clear_screen
                print_header "Update Configuration Files" "${UI_COLORS[GREEN]}"
                echo ""
                echo "Select update option:"
                echo "  1) Update specific platform"
                echo "  2) Update all platforms"
                echo "  3) Back to main menu"
                echo ""
                printf "Enter choice [1-3]: "
                read -r choice
                
                case "$choice" in
                    1)
                        local platform
                        platform=$(show_platform_menu)
                        [[ -z "$platform" ]] && continue
                        clear_screen
                        update_build_configs "$platform"
                        print_status "Press Enter to continue..." "info"
                        read -r
                        ;;
                    2)
                        clear_screen
                        update_all_configs
                        print_status "Press Enter to continue..." "info"
                        read -r
                        ;;
                    3|*)
                        continue
                        ;;
                esac
                ;;
            5) # Utils
                show_live_output "\"$SCRIPT_DIR/scripts/pk-cli-original.sh\" utils" "System Utilities"
                ;;
            6) # Status
                show_live_output "\"$SCRIPT_DIR/scripts/pk-cli-original.sh\" status" "System Status"
                ;;
            7) # Doctor
                show_live_output "\"$SCRIPT_DIR/scripts/pk-cli-original.sh\" doctor" "System Diagnostics"
                ;;
            8) # Clean
                local platform
                platform=$(show_platform_menu)
                [[ -z "$platform" ]] && continue
                show_live_output "\"$SCRIPT_DIR/scripts/pk-cli-original.sh\" clean \"$platform\"" "Cleaning $platform Build"
                ;;
            255) # Quit
                clear_screen
                pk_logo_show "static" "ascii" "Thank you for using" "PK Platform Tool"
                echo ""
                print_status "Goodbye! Happy building! ${SYMBOLS[ROCKET]}" "success"
                echo ""
                exit 0
                ;;
        esac
    done
}

# Update build configuration from templates
update_build_configs() {
    local platform="$1"
    
    if [[ -z "$platform" ]]; then
        echo "Usage: update_build_configs <platform>"
        echo "Available platforms: beaglebone, raspberrypi4, jetson-nano"
        return 1
    fi
    
    local build_dir="build-${platform}"
    local template_dir="conf-templates/${platform}"
    
    # Check if template directory exists
    if [[ ! -d "$template_dir" ]]; then
        print_status "Template directory not found: $template_dir" "error"
        return 1
    fi
    
    # Check if build directory exists
    if [[ ! -d "$build_dir" ]]; then
        print_status "Build directory not found: $build_dir" "error"
        print_status "Run setup first: ./build.sh setup $platform" "info"
        return 1
    fi
    
    print_status "Updating $platform configuration from templates..." "info"
    
    # Backup existing configs
    local backup_dir="config-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    
    if [[ -f "$build_dir/conf/local.conf" ]]; then
        cp "$build_dir/conf/local.conf" "$backup_dir/local.conf.bak"
        print_status "Backed up local.conf to $backup_dir/" "info"
    fi
    
    if [[ -f "$build_dir/conf/bblayers.conf" ]]; then
        cp "$build_dir/conf/bblayers.conf" "$backup_dir/bblayers.conf.bak"
        print_status "Backed up bblayers.conf to $backup_dir/" "info"
    fi
    
    # Copy template files
    if [[ -f "$template_dir/local.conf" ]]; then
        cp "$template_dir/local.conf" "$build_dir/conf/"
        print_status "Updated local.conf from template" "success"
    fi
    
    if [[ -f "$template_dir/bblayers.conf" ]]; then
        cp "$template_dir/bblayers.conf" "$build_dir/conf/"
        print_status "Updated bblayers.conf from template" "success"
    fi
    
    print_status "Configuration update completed!" "success"
    print_status "Backup saved in: $backup_dir/" "info"
}

# Update all platform configurations
update_all_configs() {
    local platforms=("beaglebone" "raspberrypi4" "jetson-nano")
    
    print_status "Updating all platform configurations..." "info"
    echo ""
    
    for platform in "${platforms[@]}"; do
        if [[ -d "build-${platform}" ]]; then
            print_status "Updating $platform..." "info"
            update_build_configs "$platform"
            echo ""
        else
            print_status "Skipping $platform (build directory not found)" "warning"
        fi
    done
    
    print_status "All configurations updated!" "success"
}

# Main launcher function
main() {
    # Check if pk CLI is available
    check_pk_cli
    
    # If no arguments provided, run menuconfig mode by default
    if [ $# -eq 0 ]; then
        # Launch menuconfig-style interface
        exec "$SCRIPT_DIR/scripts/menuconfig.sh"
    else
        # Handle command line arguments - pass to CLI
        case "${1:-}" in
            "-h"|"--help"|"help")
                # Show comprehensive help
                pk_logo_show "static" "gradient" "PK Platform CLI" "Help & Documentation"
                echo ""
                echo "🚀 PK Platform Development Kit"
                echo "==============================="
                echo ""
                echo "DESCRIPTION:"
                echo "  Interactive Yocto build system with multi-platform support"
                echo ""
                echo "USAGE:"
                echo "  $0                           # Launch interactive mode (default)"
                echo "  $0 [COMMAND] [OPTIONS]       # Execute specific command"
                echo ""
                echo "MAIN COMMANDS:"
                echo "  build <platform>            # Build platform image"
                echo "  setup <platform>            # Setup build environment"
                echo "  platform list               # List available platforms"
                echo "  config list                 # Show configuration status"
                echo "  update-config [platform]    # Update configuration files"
                echo "  status                       # Show system status"
                echo "  doctor                       # Run system diagnostics"
                echo "  clean <platform>            # Clean build artifacts"
                echo "  utils                        # System utilities"
                echo ""
                echo "PLATFORMS:"
                echo "  beaglebone                   # BeagleBone Black/Green (ARM Cortex-A8)"
                echo "  raspberrypi4                 # Raspberry Pi 4 64-bit (ARM Cortex-A72)"
                echo "  jetson-nano                  # NVIDIA Jetson Nano (ARM Cortex-A57)"
                echo ""
                echo "EXAMPLES:"
                echo "  $0                           # Interactive mode"
                echo "  $0 build beaglebone          # Build BeagleBone image"
                echo "  $0 setup raspberrypi4        # Setup Raspberry Pi 4"
                echo "  $0 update-config             # Update all platform configs"
                echo "  $0 status                    # Show system status"
                echo ""
                echo "OPTIONS:"
                echo "  -h, --help                   # Show this help"
                echo "  -v, --version                # Show version"
                echo "  -i, --interactive            # Force interactive mode"
                echo ""
                echo "For detailed command help: $0 <command> --help"
                echo ""
                exit 0
                ;;
            "--version"|"-v")
                exec "$SCRIPT_DIR/scripts/pk-cli-original.sh" version
                ;;
            "--interactive"|"-i")
                clear_screen
                pk_logo_show "animated" "rainbow" "PK Platform" "Interactive Tool"
                sleep 1
                run_interactive_mode
                ;;
            "update-config"|"update")
                shift
                if [[ $# -eq 0 ]]; then
                    pk_logo_show "static" "gradient" "Update Configuration" "All Platforms"
                    echo ""
                    update_all_configs
                else
                    pk_logo_show "static" "gradient" "Update Configuration" "${1}"
                    echo ""
                    update_build_configs "$1"
                fi
                ;;
            *)
                # Pass all arguments to pk CLI
                "$SCRIPT_DIR/scripts/pk-cli-original.sh" "$@"
                ;;
        esac
    fi
}

# Cleanup on exit
cleanup() {
    show_cursor
}

# Trap cleanup on exit
trap cleanup EXIT

# Main entry point
main "$@"