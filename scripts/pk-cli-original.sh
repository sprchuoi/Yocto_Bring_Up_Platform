#!/bin/bash

# PK Platform CLI - Main Build Interface
# Menu-driven command-line interface for Yocto Platform Development Kit

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source PK Logo Class
source "$SCRIPT_DIR/pk-logo-class.sh"

# Import child scripts
SCRIPTS_DIR="$SCRIPT_DIR"
source "$SCRIPTS_DIR/cli-core.sh"
source "$SCRIPTS_DIR/cli-build.sh" 
source "$SCRIPTS_DIR/cli-platform.sh"
source "$SCRIPTS_DIR/cli-config.sh"
source "$SCRIPTS_DIR/cli-utils.sh"

# Version information
CLI_VERSION="1.0.0"
CLI_NAME="PK Platform CLI"

# Show main menu
show_main_menu() {
    clear
    pk_logo_show "static" "gradient" "PK Platform CLI" "v$CLI_VERSION"
    echo ""
    echo "======================================"
    echo "       MAIN MENU"
    echo "======================================"
    echo ""
    echo "  1) Build Image"
    echo "  2) Setup Environment"
    echo "  3) Configuration Menu"
    echo "  4) Kernel Menu"
    echo "  5) Source Management"
    echo "  6) System Status"
    echo "  7) Clean Build"
    echo "  8) Help"
    echo "  0) Exit"
    echo ""
    echo "======================================"
    printf "Select option [0-8]: "
}

# Show configuration menu
show_config_menu() {
    clear
    pk_logo_show "static" "ascii" "Configuration" "Management"
    echo ""
    echo "======================================"
    echo "    CONFIGURATION MENU"
    echo "======================================"
    echo ""
    echo "  1) Show Configuration"
    echo "  2) Edit local.conf"
    echo "  3) Edit bblayers.conf"
    echo "  4) Update from Templates"
    echo "  5) Backup Configuration"
    echo "  6) Restore Configuration"
    echo "  0) Back to Main Menu"
    echo ""
    echo "======================================"
    printf "Select option [0-6]: "
}

# Show kernel menu
show_kernel_menu() {
    clear
    pk_logo_show "static" "ascii" "Kernel" "Configuration"
    echo ""
    echo "======================================"
    echo "       KERNEL MENU"
    echo "======================================"
    echo ""
    echo "  1) Configure Kernel (menuconfig)"
    echo "  2) Build Kernel Only"
    echo "  3) Clean Kernel"
    echo "  4) Show Kernel Info"
    echo "  5) Deploy Kernel"
    echo "  0) Back to Main Menu"
    echo ""
    echo "======================================"
    printf "Select option [0-5]: "
}

# Show source management menu
show_source_menu() {
    clear
    pk_logo_show "static" "ascii" "Source" "Management"
    echo ""
    echo "======================================"
    echo "    SOURCE MANAGEMENT"
    echo "======================================"
    echo ""
    echo "  1) Update Submodules"
    echo "  2) Clean Downloads"
    echo "  3) Clean Shared State"
    echo "  4) Show Source Status"
    echo "  5) Fetch All Sources"
    echo "  0) Back to Main Menu"
    echo ""
    echo "======================================"
    printf "Select option [0-5]: "
}

# Select platform
select_platform() {
    echo ""
    echo "Available Platforms:"
    echo "  1) beaglebone"
    echo "  2) raspberrypi4"
    echo "  3) jetson-nano"
    echo ""
    printf "Select platform [1-3]: "
    read -r choice
    
    case "$choice" in
        1) echo "beaglebone" ;;
        2) echo "raspberrypi4" ;;
        3) echo "jetson-nano" ;;
        *) echo "" ;;
    esac
}

# Main CLI entry point
main() {
    # Check if command line arguments provided
    if [ $# -gt 0 ]; then
        # Don't display logo when called from wrapper (build.sh already shows it)
        # pk_logo_show "popup" "gradient" "PK Platform CLI" "v$CLI_VERSION"
        
        # Parse command line arguments
        case "${1:-help}" in
            # Build commands
            "build"|"b")
                shift
                local platform="${1:-}"
                if [ -z "$platform" ]; then
                    print_error "Platform required"
                    echo "Usage: build <platform>"
                    exit 1
                fi
                
                # Ensure we're in the project root directory
                local project_root="$(dirname "$SCRIPT_DIR")"
                cd "$project_root" || {
                    print_error "Failed to change to project directory: $project_root"
                    exit 1
                }
                
                cli_build_command "$platform"
                ;;
            
            # Setup commands
            "setup"|"s")
                shift
                local platform="${1:-}"
                if [ -z "$platform" ]; then
                    print_error "Platform required"
                    echo "Usage: setup <platform>"
                    exit 1
                fi
                
                print_info "Setting up $platform environment..."
                
                # Ensure we're in the project root directory
                local project_root="$(dirname "$SCRIPT_DIR")"
                cd "$project_root" || {
                    print_error "Failed to change to project directory: $project_root"
                    exit 1
                }
                
                # Run setup script - use bash to execute it properly
                if [ -f "scripts/setup-build.sh" ]; then
                    bash scripts/setup-build.sh "$platform"
                elif [ -f "./setup-build.sh" ]; then
                    bash ./setup-build.sh "$platform"
                else
                    print_error "setup-build.sh not found"
                    exit 1
                fi
                ;;
            
            # Configuration management  
            "config"|"c")
                shift
                cli_config_command "$@"
                ;;
            
            # Utilities
            "utils"|"u")
                shift
                print_info "Utilities"
                echo "Available: doctor, logs"
                ;;
            
            "status")
                # Ensure we're in the project root directory
                local project_root="$(dirname "$SCRIPT_DIR")"
                cd "$project_root" || {
                    print_error "Failed to change to project directory: $project_root"
                    exit 1
                }
                
                # Inline status command
                echo ""
                echo "System Status"
                echo "============="
                echo ""
                
                # Check Git repository
                if git rev-parse --git-dir > /dev/null 2>&1; then
                    echo "✓ Git repository: $(basename "$(git rev-parse --show-toplevel)")"
                    echo "✓ Current branch: $(git branch --show-current)"
                else
                    echo "✗ Git repository: Not found"
                fi
                
                # Check submodules
                if [ -d "poky" ]; then
                    echo "✓ Poky submodule: Available"
                else
                    echo "✗ Poky submodule: Missing"
                fi
                
                if [ -d "meta-openembedded" ]; then
                    echo "✓ Meta-openembedded: Available" 
                else
                    echo "✗ Meta-openembedded: Missing"
                fi
                
                # Check build directories
                echo ""
                echo "Build Directories:"
                for plt in beaglebone raspberrypi4 jetson-nano; do
                    if [ -d "build-$plt" ]; then
                        echo "✓ build-$plt: Exists"
                    else
                        echo "- build-$plt: Not created"
                    fi
                done
                
                # Check disk space
                echo ""
                echo "Disk Space:"
                df -h . | tail -1 | awk '{print "Available: " $4 " (Used: " $5 ")"}'
                ;;
            
            "clean")
                shift
                local target="${1:-help}"
                
                # Ensure we're in the project root directory
                local project_root="$(dirname "$SCRIPT_DIR")"
                cd "$project_root" || {
                    print_error "Failed to change to project directory: $project_root"
                    exit 1
                }
                
                case "$target" in
                    "beaglebone"|"raspberrypi4"|"jetson-nano")
                        print_warning "Cleaning build-$target..."
                        rm -rf "build-$target"
                        print_success "✓ build-$target cleaned"
                        ;;
                    *)
                        echo "Usage: clean <platform>"
                        echo "Platforms: beaglebone, raspberrypi4, jetson-nano"
                        ;;
                esac
                ;;
            
            # Version
            "version"|"v"|"-v"|"--version")
                echo "PK Platform CLI v$CLI_VERSION"
                echo "Yocto Platform Development Kit"
                echo ""
                echo "Supported Platforms:"
                echo "  - BeagleBone Black/Green"
                echo "  - Raspberry Pi 4 64-bit"
                echo "  - NVIDIA Jetson Nano"
                ;;
            
            # Help
            "help"|"h"|"-h"|"--help")
                echo "PK Platform CLI v$CLI_VERSION"
                echo ""
                echo "Usage: $0 [COMMAND] [OPTIONS]"
                echo ""
                echo "Commands:"
                echo "  build <platform>    - Build platform image"
                echo "  setup <platform>    - Setup build environment"
                echo "  config list         - Show configuration"
                echo "  status              - Show system status"
                echo "  clean <platform>    - Clean build directory"
                echo "  version             - Show version"
                echo "  help                - Show this help"
                echo ""
                echo "Platforms: beaglebone, raspberrypi4, jetson-nano"
                echo ""
                echo "For interactive menu: run without arguments"
                ;;
            
            *)
                print_error "Unknown command: $1"
                echo ""
                cli_help_command
                exit 1
                ;;
        esac
        return 0
    fi
    
    # Interactive menu mode
    while true; do
        show_main_menu
        read -r choice
        
        case "$choice" in
            1) # Build Image
                platform=$(select_platform)
                if [ -n "$platform" ]; then
                    cli_build_command "$platform"
                    echo ""
                    printf "Press Enter to continue..."
                    read -r
                fi
                ;;
                
            2) # Setup Environment
                platform=$(select_platform)
                if [ -n "$platform" ]; then
                    print_info "Setting up $platform environment..."
                    
                    # Run setup script
                    if [ -f "scripts/setup-build.sh" ]; then
                        ./scripts/setup-build.sh "$platform"
                    else
                        print_error "setup-build.sh not found"
                    fi
                    
                    echo ""
                    printf "Press Enter to continue..."
                    read -r
                fi
                ;;
                
            3) # Configuration Menu
                while true; do
                    show_config_menu
                    read -r config_choice
                    
                    case "$config_choice" in
                        1) # Show Configuration
                            cli_config_command list
                            echo ""
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        2) # Edit local.conf
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                ${EDITOR:-nano} "build-${platform}/conf/local.conf"
                            fi
                            ;;
                        3) # Edit bblayers.conf
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                ${EDITOR:-nano} "build-${platform}/conf/bblayers.conf"
                            fi
                            ;;
                        4) # Update from Templates
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Updating $platform configuration from templates..."
                                cp "conf-templates/${platform}/local.conf" "build-${platform}/conf/" 2>/dev/null && \
                                cp "conf-templates/${platform}/bblayers.conf" "build-${platform}/conf/" 2>/dev/null && \
                                print_success "Configuration updated!" || print_error "Failed to update"
                                echo ""
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        5) # Backup Configuration
                            print_info "Creating backup..."
                            backup_dir="config-backup-$(date +%Y%m%d-%H%M%S)"
                            mkdir -p "$backup_dir"
                            for p in beaglebone raspberrypi4 jetson-nano; do
                                if [ -d "build-$p/conf" ]; then
                                    cp -r "build-$p/conf" "$backup_dir/$p/"
                                fi
                            done
                            print_success "Backup created: $backup_dir"
                            echo ""
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        6) # Restore Configuration
                            print_info "Restore not implemented yet"
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        0) break ;;
                        *) 
                            print_error "Invalid option"
                            sleep 1
                            ;;
                    esac
                done
                ;;
                
            4) # Kernel Menu
                while true; do
                    show_kernel_menu
                    read -r kernel_choice
                    
                    case "$kernel_choice" in
                        1) # Configure Kernel
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Launching kernel menuconfig for $platform..."
                                cd "build-${platform}" 2>/dev/null || { print_error "Build directory not found"; sleep 2; continue; }
                                source ../poky/oe-init-build-env "build-${platform}" >/dev/null 2>&1
                                bitbake -c menuconfig virtual/kernel
                                cd ..
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        2) # Build Kernel Only
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Building kernel for $platform..."
                                cd "build-${platform}" 2>/dev/null || { print_error "Build directory not found"; sleep 2; continue; }
                                source ../poky/oe-init-build-env "build-${platform}" >/dev/null 2>&1
                                bitbake virtual/kernel
                                cd ..
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        3) # Clean Kernel
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Cleaning kernel for $platform..."
                                cd "build-${platform}" 2>/dev/null || { print_error "Build directory not found"; sleep 2; continue; }
                                source ../poky/oe-init-build-env "build-${platform}" >/dev/null 2>&1
                                bitbake -c clean virtual/kernel
                                cd ..
                                print_success "Kernel cleaned"
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        4) # Show Kernel Info
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Kernel information for $platform:"
                                if [ -f "build-${platform}/conf/local.conf" ]; then
                                    grep -i "PREFERRED_VERSION.*kernel" "build-${platform}/conf/local.conf" || echo "No kernel version specified"
                                fi
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        5) # Deploy Kernel
                            print_info "Deploy kernel not implemented yet"
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        0) break ;;
                        *) 
                            print_error "Invalid option"
                            sleep 1
                            ;;
                    esac
                done
                ;;
                
            5) # Source Management
                while true; do
                    show_source_menu
                    read -r source_choice
                    
                    case "$source_choice" in
                        1) # Update Submodules
                            print_info "Updating Git submodules..."
                            git submodule update --init --recursive
                            print_success "Submodules updated"
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        2) # Clean Downloads
                            print_warning "This will delete all downloaded source files!"
                            printf "Continue? [y/N]: "
                            read -r confirm
                            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                                print_info "Cleaning downloads..."
                                rm -rf downloads/*
                                print_success "Downloads cleaned"
                            fi
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        3) # Clean Shared State
                            print_warning "This will delete the shared state cache!"
                            printf "Continue? [y/N]: "
                            read -r confirm
                            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                                print_info "Cleaning shared state..."
                                rm -rf sstate-cache/*
                                print_success "Shared state cleaned"
                            fi
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        4) # Show Source Status
                            print_info "Source Status:"
                            echo ""
                            echo "Git Submodules:"
                            git submodule status
                            echo ""
                            if [ -d "downloads" ]; then
                                echo "Downloads: $(du -sh downloads 2>/dev/null | cut -f1)"
                            fi
                            if [ -d "sstate-cache" ]; then
                                echo "Shared State: $(du -sh sstate-cache 2>/dev/null | cut -f1)"
                            fi
                            printf "Press Enter to continue..."
                            read -r
                            ;;
                        5) # Fetch All Sources
                            platform=$(select_platform)
                            if [ -n "$platform" ]; then
                                print_info "Fetching all sources for $platform..."
                                cd "build-${platform}" 2>/dev/null || { print_error "Build directory not found"; sleep 2; continue; }
                                source ../poky/oe-init-build-env "build-${platform}" >/dev/null 2>&1
                                bitbake -c fetchall core-image-minimal
                                cd ..
                                print_success "Sources fetched"
                                printf "Press Enter to continue..."
                                read -r
                            fi
                            ;;
                        0) break ;;
                        *) 
                            print_error "Invalid option"
                            sleep 1
                            ;;
                    esac
                done
                ;;
                
            6) # System Status
                echo ""
                echo "System Status"
                echo "============="
                echo ""
                
                # Check Git repository
                if git rev-parse --git-dir > /dev/null 2>&1; then
                    echo "✓ Git repository: $(basename "$(git rev-parse --show-toplevel)")"
                    echo "✓ Current branch: $(git branch --show-current)"
                else
                    echo "✗ Git repository: Not found"
                fi
                
                # Check submodules
                if [ -d "poky" ]; then
                    echo "✓ Poky submodule: Available"
                else
                    echo "✗ Poky submodule: Missing"
                fi
                
                if [ -d "meta-openembedded" ]; then
                    echo "✓ Meta-openembedded: Available" 
                else
                    echo "✗ Meta-openembedded: Missing"
                fi
                
                # Check build directories
                echo ""
                echo "Build Directories:"
                for plt in beaglebone raspberrypi4 jetson-nano; do
                    if [ -d "build-$plt" ]; then
                        echo "✓ build-$plt: Exists"
                    else
                        echo "- build-$plt: Not created"
                    fi
                done
                
                # Check disk space
                echo ""
                echo "Disk Space:"
                df -h . | tail -1 | awk '{print "Available: " $4 " (Used: " $5 ")"}'
                
                echo ""
                printf "Press Enter to continue..."
                read -r
                ;;
                
            7) # Clean Build
                platform=$(select_platform)
                if [ -n "$platform" ]; then
                    print_warning "Cleaning build-$platform..."
                    rm -rf "build-$platform"
                    print_success "✓ build-$platform cleaned"
                    echo ""
                    printf "Press Enter to continue..."
                    read -r
                fi
                ;;
                
            8) # Help
                echo ""
                echo "PK Platform CLI v$CLI_VERSION"
                echo ""
                echo "Interactive Menu Help:"
                echo "  1) Build Image - Build platform images"
                echo "  2) Setup - Setup build environment"
                echo "  3) Configuration - Manage configurations"
                echo "  4) Kernel - Kernel configuration and build"
                echo "  5) Source - Manage source code and cache"
                echo "  6) Status - Show system status"
                echo "  7) Clean - Clean build artifacts"
                echo "  8) Help - This help message"
                echo "  0) Exit - Exit the program"
                echo ""
                printf "Press Enter to continue..."
                read -r
                ;;
                
            0) # Exit
                clear
                pk_logo_show "static" "ascii" "Thank You" "PK Platform"
                echo ""
                print_success "Goodbye! Happy building!"
                echo ""
                exit 0
                ;;
                
            *)
                print_error "Invalid option. Please select 0-8"
                sleep 1
                ;;
        esac
    done
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    cd "$(dirname "$SCRIPT_DIR")" 2>/dev/null || true
    main "$@"
fi