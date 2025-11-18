# Multi-Platform Yocto Build Project

This repository contains the Yocto Project setup for building custom Linux images for multiple embedded platforms:

- **BeagleBone** (ARM Cortex-A8)
- **Raspberry Pi 4** (ARM Cortex-A72 64-bit)
- **NVIDIA Jetson Nano** (ARM Cortex-A57 with GPU acceleration)

## Project Structure

- `poky/` - The core Yocto Project repository (submodule)
- `meta-openembedded/` - Additional OpenEmbedded layers (submodule)
- `meta-raspberrypi/` - Raspberry Pi BSP layer (submodule)
- `meta-tegra/` - NVIDIA Jetson/Tegra BSP layer (submodule)
- `conf-templates/` - Platform-specific configuration templates
  - `beaglebone/` - BeagleBone configuration
  - `raspberrypi4/` - Raspberry Pi 4 configuration
  - `jetson-nano/` - Jetson Nano configuration
- `build-[platform]/` - Build directories (excluded from Git)

## Setup Instructions

1. Clone this repository:
   ```bash
   git clone <your-repo-url>
   cd Yocto_build_custom
   ```

2. Initialize submodules:
   ```bash
   git submodule update --init --recursive
   ```

3. Set up and build in one step:
   ```bash
   # Setup and build automatically
   ./setup-build.sh raspberrypi4 --build
   
   # Setup only (manual build later)
   ./setup-build.sh raspberrypi4
   
   # Clean build
   ./setup-build.sh jetson-nano --clean --build
   ```

4. Or use the advanced build script:
   ```bash
   # Advanced build with monitoring
   ./build.sh raspberrypi4 core-image-minimal
   
   # Build with options
   ./build.sh jetson-nano core-image-base --clean --sdk
   
   # Build specific package only
   ./build.sh beaglebone --package=linux-yocto
   ```

### Available Scripts

- **`setup-build.sh`** - Quick setup and optional build
- **`build.sh`** - Advanced build script with monitoring and options

### Build Script Options

```bash
# Basic usage
./setup-build.sh [platform] [--build] [--clean]
./build.sh [platform] [image] [options]

# Examples
./setup-build.sh raspberrypi4 --build=core-image-base
./build.sh jetson-nano core-image-minimal --clean --verbose
./build.sh beaglebone --package=u-boot --force
```

## Supported Platforms

### BeagleBone
- **Target**: `beaglebone-yocto`
- **Architecture**: ARM Cortex-A8
- **Features**: Basic embedded Linux with U-Boot
- **Build directory**: `build-beaglebone/`

### Raspberry Pi 4
- **Target**: `raspberrypi4-64`
- **Architecture**: ARM Cortex-A72 64-bit
- **Features**: GPU acceleration, WiFi/Bluetooth, hardware interfaces
- **Build directory**: `build-raspberrypi4/`

### NVIDIA Jetson Nano
- **Target**: `jetson-nano-devkit`
- **Architecture**: ARM Cortex-A57 with NVIDIA GPU
- **Features**: CUDA support, TensorRT, computer vision libraries
- **Build directory**: `build-jetson-nano/`

## Build Optimizations
All platforms are configured with:
- Limited parallel jobs to avoid race conditions
- Clock skew fixes for virtualized environments
- Platform-specific optimizations

## Output

Built images will be available in:
```
build-[platform]/tmp/deploy/images/[machine]/
```

### Common Output Files
- `core-image-minimal-[machine].wic` - Flashable SD card image
- `core-image-minimal-[machine].tar.bz2` - Root filesystem archive
- Bootloader files (U-Boot for BeagleBone/RPi, L4T for Jetson)
- Linux kernel (`zImage` or `Image`)
- Device tree files (`.dtb`)

## Flashing to SD Card

### BeagleBone & Raspberry Pi 4
```bash
sudo dd if=core-image-minimal-[machine].wic of=/dev/sdX bs=1M status=progress
sync
```

### Jetson Nano
For Jetson Nano, you'll typically need to use NVIDIA's flashing tools or the generated `.wic` image with the Jetson flash utility.

## Platform Comparison

| Feature | BeagleBone | Raspberry Pi 4 | Jetson Nano |
|---------|------------|----------------|-------------|
| CPU | ARM Cortex-A8 | ARM Cortex-A72 64-bit | ARM Cortex-A57 |
| RAM | 512MB | 1GB-8GB | 4GB |
| GPU | None | VideoCore VI | NVIDIA Maxwell 128-core |
| WiFi/BT | Optional | Built-in | Built-in |
| AI/ML | Limited | Basic | CUDA/TensorRT |
| Use Case | Basic IoT | General purpose | AI/Computer Vision |

## Build Requirements

- Ubuntu 20.04+ or equivalent
- At least 120GB free disk space (40GB per platform)
- 8GB+ RAM recommended (16GB for Jetson builds)
- Required packages: `lz4`, `zstd`
- For Jetson: Accept NVIDIA licenses in configuration

## Troubleshooting

### Common Issues
1. **Clock skew errors**: Fixed with `SOURCE_DATE_EPOCH` configuration
2. **binutils build failures**: Fixed with single-threaded binutils compilation
3. **Missing compression tools**: Install with `sudo apt install lz4 zstd`

### Build Logs
Check build logs in:
```
build-beaglebone/tmp/log/
build-beaglebone/tmp/work/*/temp/log.*
```

## License

This project follows the Yocto Project licensing. See individual components for their specific licenses.