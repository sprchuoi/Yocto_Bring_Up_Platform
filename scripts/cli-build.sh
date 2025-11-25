#!/bin/bash

# CLI Build Functions
# Build management functionality for the PK Platform CLI

# Main build command handler
cli_build_command() {
    local platform="${1:-help}"
    local image="${2:-minimal}"
    local clean_flag=false
    local continue_flag=false
    local verbose_flag=false
    local monitor_flag=false
    local logs_flag=false
    
    # Parse options
    shift 2 2>/dev/null || shift $# # Handle case where we have fewer than 2 args
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_flag=true
                shift
                ;;
            --continue)
                continue_flag=true
                shift
                ;;
            --verbose)
                verbose_flag=true
                shift
                ;;
            --monitor)
                monitor_flag=true
                shift
                ;;
            --logs)
                logs_flag=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_build_usage
                return 1
                ;;
        esac
    done
    
    # Handle help
    if [[ "$platform" == "help" || "$platform" == "-h" || "$platform" == "--help" ]]; then
        show_build_usage
        return 0
    fi
    
    # Validate platform
    if ! validate_platform "$platform"; then
        print_error "Invalid platform: $platform"
        print_info "Valid platforms: beaglebone, raspberrypi4, jetson-nano"
        return 1
    fi
    
    # Validate image
    if ! validate_image "$image"; then
        print_error "Invalid image: $image"
        print_info "Valid images: minimal, base, full"
        return 1
    fi
    
    # Normalize image name
    image=$(normalize_image_name "$image")
    
    # Check workspace
    if ! check_workspace; then
        return 1
    fi
    
    # Check build prerequisites
    if ! check_build_prereqs "$platform"; then
        return 1
    fi
    
    # Execute build
    execute_build "$platform" "$image" "$clean_flag" "$continue_flag" "$verbose_flag" "$monitor_flag" "$logs_flag"
}

# Execute the actual build
execute_build() {
    local platform="$1"
    local image="$2"
    local clean="$3"
    local continue="$4"
    local verbose="$5"
    local monitor="$6"
    local show_logs="$7"
    
    local build_dir="build-$platform"
    local start_time=$(date +%s)
    local original_dir="$(pwd)"
    
    print_header "Starting build for $platform"
    print_info "Image: $image"
    print_info "Build directory: $build_dir"
    
    # Show PK logo before build
    pk_logo_show "animated" "fire" "Building $platform" "Please wait..."
    
    # Change to build directory
    cd "$build_dir" || {
        print_error "Failed to enter build directory: $build_dir"
        return 1
    }
    
    # Source bitbake environment
    if ! source ../poky/oe-init-build-env . >/dev/null 2>&1; then
        print_error "Failed to source bitbake environment"
        return 1
    fi
    
    # Prepare build command
    local build_cmd="bitbake"
    
    if [ "$clean" = true ]; then
        print_info "Cleaning build..."
        $build_cmd -c cleanall "$image" 2>&1 | tee ../logs/build-clean.log
    fi
    
    if [ "$continue" = true ]; then
        print_info "Continuing interrupted build..."
        build_cmd="$build_cmd -c compile"
    fi
    
    if [ "$verbose" = true ]; then
        build_cmd="$build_cmd -v"
    fi
    
    build_cmd="$build_cmd $image"
    
    print_info "Build command: $build_cmd"
    echo ""
    
    # Execute build with monitoring
    local build_result=0
    if [ "$monitor" = true ]; then
        execute_build_with_monitoring "$build_cmd" "$platform" "$image" "$start_time"
        build_result=$?
    else
        execute_build_simple "$build_cmd" "$platform" "$image" "$start_time" "$show_logs"
        build_result=$?
    fi
    
    # Return to original directory
    cd "$original_dir" || true
    
    return $build_result
}

# Simple build execution
execute_build_simple() {
    local build_cmd="$1"
    local platform="$2"
    local image="$3"
    local start_time="$4"
    local show_logs="$5"
    
    local log_file="../logs/build-${platform}-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p ../logs
    
    print_info "Build started at $(date)"
    print_info "Log file: $log_file"
    
    # Execute build
    if [ "$show_logs" = true ]; then
        $build_cmd 2>&1 | tee "$log_file"
    else
        $build_cmd >"$log_file" 2>&1 &
        local build_pid=$!
        show_spinner $build_pid "Building $platform ($image)..."
        wait $build_pid
    fi
    
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        print_success "Build completed successfully!"
        print_info "Duration: $(format_duration $duration)"
        show_build_results "$platform" "$image"
    else
        print_error "Build failed with exit code $exit_code"
        print_info "Check log file: $log_file"
        show_build_error_help
    fi
    
    return $exit_code
}

# Build execution with monitoring
execute_build_with_monitoring() {
    local build_cmd="$1"
    local platform="$2"
    local image="$3"
    local start_time="$4"
    
    local log_file="../logs/build-${platform}-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p ../logs
    
    print_header "Build Monitor"
    print_info "Platform: $platform"
    print_info "Image: $image"
    print_info "Started: $(date)"
    echo ""
    
    # Execute build with real-time monitoring
    $build_cmd 2>&1 | tee "$log_file" | while IFS= read -r line; do
        # Parse build progress
        if [[ "$line" =~ "NOTE: Running task" ]]; then
            local task=$(echo "$line" | sed -n 's/.*Running task \([0-9]*\) of \([0-9]*\).*/\1 \2/p')
            if [[ -n "$task" ]]; then
                local current=$(echo "$task" | cut -d' ' -f1)
                local total=$(echo "$task" | cut -d' ' -f2)
                show_progress "$current" "$total" "Building"
            fi
        elif [[ "$line" =~ "ERROR" ]]; then
            echo ""
            print_error "Build error detected"
            echo "$line"
        fi
    done
    
    local exit_code=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        print_success "Build completed successfully!"
        print_info "Duration: $(format_duration $duration)"
        show_build_results "$platform" "$image"
    else
        print_error "Build failed with exit code $exit_code"
        show_build_error_help
    fi
    
    return $exit_code
}

# Show build results
show_build_results() {
    local platform="$1"
    local image="$2"
    local deploy_dir="tmp/deploy/images"
    
    print_header "Build Results"
    
    if [ -d "$deploy_dir" ]; then
        local machine_dir=$(ls "$deploy_dir" | head -1)
        if [ -n "$machine_dir" ] && [ -d "$deploy_dir/$machine_dir" ]; then
            print_info "Output directory: $deploy_dir/$machine_dir"
            
            # List important files
            echo ""
            print_subheader "Generated Images:"
            ls -lh "$deploy_dir/$machine_dir"/*.{img,wic,tar.gz,tar.xz} 2>/dev/null | \
                awk '{print "  " $9 " (" $5 ")"}'
            
            # Show total size
            local total_size=$(du -sb "$deploy_dir/$machine_dir" 2>/dev/null | cut -f1)
            if [ -n "$total_size" ]; then
                print_info "Total output size: $(format_size $total_size)"
            fi
        fi
    fi
    
    print_info "Build completed for $platform"
}

# Show build error help
show_build_error_help() {
    print_header "Build Troubleshooting"
    echo ""
    print_info "Common solutions:"
    echo "  1. Clean build: pk build $platform --clean"
    echo "  2. Check disk space: df -h"
    echo "  3. Update submodules: git submodule update"
    echo "  4. Check logs: pk utils logs $platform"
    echo ""
    print_info "For detailed logs, use: pk build $platform --logs --verbose"
}

# Show build usage
show_build_usage() {
    cat << EOF
$(print_header "BUILD COMMAND USAGE")

SYNTAX:
    pk build [PLATFORM] [IMAGE] [OPTIONS]

PLATFORMS:
    beaglebone      BeagleBone Industrial IoT configuration
    raspberrypi4    Raspberry Pi 4 Industrial configuration  
    jetson-nano     NVIDIA Jetson Nano configuration

IMAGES:
    minimal         core-image-minimal (default, ~100MB)
    base            core-image-base (~200MB)
    full            core-image-full-cmdline (~500MB)

OPTIONS:
    --clean         Clean build before starting
    --continue      Continue interrupted build
    --verbose       Show verbose build output
    --monitor       Real-time build monitoring
    --logs          Show build logs during build

EXAMPLES:
    pk build beaglebone                     # Build minimal image
    pk build raspberrypi4 base              # Build base image
    pk build jetson-nano full --clean       # Clean build of full image
    pk build beaglebone minimal --monitor   # Build with monitoring

QUICK BUILDS:
    pk build beaglebone                     # ~30-60 minutes
    pk build raspberrypi4                   # ~45-90 minutes
    pk build jetson-nano                    # ~60-120 minutes

BUILD OUTPUT:
    Images are saved to: build-[platform]/tmp/deploy/images/

EOF
}