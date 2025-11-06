# Yocto BeagleBone Build Project

This repository contains the Yocto Project setup for building custom Linux images for BeagleBone devices.

## Project Structure

- `poky/` - The core Yocto Project repository (submodule)
- `meta-openembedded/` - Additional OpenEmbedded layers (submodule)
- `build-beaglebone/` - Build directory (excluded from Git)
- `build-beaglebone/conf/` - Build configuration files

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

3. Set up the build environment:
   ```bash
   source poky/oe-init-build-env build-beaglebone
   ```

4. Build the minimal image:
   ```bash
   bitbake core-image-minimal
   ```

## Configuration

### Machine Configuration
- Target: `beaglebone-yocto`
- Architecture: ARM Cortex-A8
- Configured in: `build-beaglebone/conf/local.conf`

### Build Optimizations
The build is configured with:
- Limited parallel jobs to avoid race conditions
- Clock skew fixes for virtualized environments
- Optimized settings for binutils and QEMU builds

## Output

Built images will be available in:
```
build-beaglebone/tmp/deploy/images/beaglebone-yocto/
```

Key files:
- `core-image-minimal-beaglebone-yocto.wic` - Flashable SD card image
- `u-boot.img` - Bootloader
- `zImage` - Linux kernel
- Device tree files (`.dtb`)

## Flashing to SD Card

```bash
sudo dd if=core-image-minimal-beaglebone-yocto.wic of=/dev/sdX bs=1M status=progress
sync
```

Replace `/dev/sdX` with your SD card device.

## Build Requirements

- Ubuntu 20.04+ or equivalent
- At least 90GB free disk space
- 8GB+ RAM recommended
- Required packages: `lz4`, `zstd`

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