1# Platform Quick Reference

## Quick Start Commands

### BeagleBone (Default)
```bash
# Setup and build in one command
./setup-build.sh beaglebone --build

# Or use advanced build script
./build.sh beaglebone core-image-minimal

# Output: build-beaglebone/tmp/deploy/images/beaglebone-yocto/
```

### Raspberry Pi 4
```bash
# Setup and build in one command
./setup-build.sh raspberrypi4 --build
1111
# Or with advanced options
./build.sh raspberrypi4 core-image-minimal --clean --verbose

# Output: build-raspberrypi4/tmp/deploy/images/raspberrypi4-64/
```

### Jetson Nano
```bash
# Setup and build in one command
./setup-build.sh jetson-nano --build

# Or with SDK generation
./build.sh jetson-nano core-image-base --sdk

# Output: build-jetson-nano/tmp/deploy/images/jetson-nano-devkit/
```

## Build Script Comparison

### setup-build.sh (Simple)
- Quick setup with optional build
- Good for first-time setup
- Basic build functionality

```bash
./setup-build.sh [platform] [--build] [--clean]
```

### build.sh (Advanced)
- Full-featured build script
- Progress monitoring
- Advanced options
- Build time estimation

```bash
./build.sh [platform] [image] [--clean] [--sdk] [--verbose] [etc.]
```

## Platform-Specific Images

### BeagleBone
- `core-image-minimal` - Basic Linux system
- `core-image-base` - Minimal with package management
- `core-image-full-cmdline` - Full command-line system

### Raspberry Pi 4
- `core-image-minimal` - Basic Linux system
- `rpi-hwup-image` - Hardware demonstration image
- `core-image-base` - With package management and RPi tools

### Jetson Nano
- `core-image-minimal` - Basic Linux system
- `tegra-minimal-initramfs` - Minimal initramfs
- Custom images with CUDA/AI frameworks

## Hardware Features by Platform

### BeagleBone
- Low power consumption
- Real-time capabilities
- Industrial I/O
- CAN bus support

### Raspberry Pi 4
- GPU acceleration (VideoCore VI)
- 4K video playback
- WiFi 802.11ac & Bluetooth 5.0
- GPIO, SPI, I2C, UART
- Camera and display interfaces

### Jetson Nano
- NVIDIA Maxwell GPU (128 CUDA cores)
- Hardware video encoding/decoding
- Deep learning inference
- Computer vision acceleration
- AI development platform

## Build Time Estimates

| Platform | First Build | Incremental |
|----------|-------------|-------------|
| BeagleBone | 2-3 hours | 10-30 min |
| Raspberry Pi 4 | 3-4 hours | 15-45 min |
| Jetson Nano | 4-6 hours | 20-60 min |

*Times vary based on system specs and network speed*

## Common Issues & Solutions

### All Platforms
- **Clock skew**: Fixed with SOURCE_DATE_EPOCH
- **Parallel build issues**: Configured per-package limits
- **Disk space**: Ensure 40GB+ per platform

### Raspberry Pi 4
- **GPU memory**: Configured with GPU_MEM = "128"
- **WiFi firmware**: Included in image
- **Video codecs**: Commercial license accepted

### Jetson Nano
- **NVIDIA licenses**: Must accept FSL_EULA
- **CUDA version**: Set to 10.2 for compatibility
- **Large downloads**: L4T components are significant

## Switching Between Platforms

To work with multiple platforms simultaneously:
```bash
# Build for RPi4
./setup-build.sh raspberrypi4 --build

# Switch to Jetson (in new terminal)
./setup-build.sh jetson-nano --build

# All builds maintain separate directories
ls build-*
```

## Common Build Scenarios

### Development Build (Fast)
```bash
# Incremental build for development
./build.sh raspberrypi4 core-image-minimal --continue
```

### Clean Production Build
```bash
# Full clean build for release
./build.sh jetson-nano core-image-base --clean --sdk --verbose
```

### Package Development
```bash
# Build specific package only
./build.sh beaglebone --package=linux-yocto --force
./build.sh raspberrypi4 --package=gstreamer1.0
```

### Testing Build
```bash
# Dry run to see what would be built
./build.sh jetson-nano core-image-minimal --dry-run

# Build with custom parallel jobs
./build.sh raspberrypi4 core-image-base --parallel=2
```

## Build Monitoring

The `build.sh` script provides real-time monitoring:
- **Progress indicators** with colored output
- **Build time estimation** based on platform
- **Disk space checking** before build
- **Automatic log capture** with timestamps
- **Error highlighting** in build output

Example output:
```
🚀 Yocto Build Script for raspberrypi4
==================================
✅ Disk space: 85GB available
⏱️  Estimated build time: 3-4 hours
🔧 Setting up build environment...
📋 Copying platform configuration...
🖼️  Building image: core-image-minimal
🏗️  Starting build...
```