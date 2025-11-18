SUMMARY = "Custom Raspberry Pi 4 hardware interface initialization scripts"
DESCRIPTION = "Scripts to initialize and configure SSH, WiFi, Docker, CAN, CAN-FD, UART, SPI, and Ethernet on Raspberry Pi 4"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "bash docker wpa-supplicant can-utils"

# Version with patch support
PV = "1.0.0"
PR = "r0"

COMPATIBLE_MACHINE = "raspberrypi4-64"

SRC_URI = " \
    file://rpi4-hardware-init.sh \
    file://rpi4-can-setup.sh \
    file://rpi4-uart-setup.sh \
    file://rpi4-spi-setup.sh \
    file://rpi4-hardware-init.service \
    file://rpi4-can-fd-support.patch;apply=yes \
    file://rpi4-docker-optimization.patch;apply=yes \
    "

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "rpi4-hardware-init.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${systemd_unitdir}/system
    install -d ${D}${sysconfdir}/rpi4
    install -d ${D}${localstatedir}/log
    
    # Install scripts with rpi4 prefix
    install -m 0755 ${WORKDIR}/rpi4-hardware-init.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/rpi4-can-setup.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/rpi4-uart-setup.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/rpi4-spi-setup.sh ${D}${bindir}/
    
    # Install systemd service
    install -m 0644 ${WORKDIR}/rpi4-hardware-init.service ${D}${systemd_unitdir}/system/
    
    # Create RPi4 configuration directory
    echo "Raspberry Pi 4 Industrial Configuration v${PV}-${PR}" > ${D}${sysconfdir}/rpi4/version
    echo "Features: SSH, WiFi, Docker, CAN-FD, UART, SPI, Ethernet" >> ${D}${sysconfdir}/rpi4/version
    
    # Create log directory
    touch ${D}${localstatedir}/log/hardware-init.log
}

FILES:${PN} += " \
    ${bindir}/rpi4-hardware-init.sh \
    ${bindir}/rpi4-can-setup.sh \
    ${bindir}/rpi4-uart-setup.sh \
    ${bindir}/rpi4-spi-setup.sh \
    ${systemd_unitdir}/system/rpi4-hardware-init.service \
    ${sysconfdir}/rpi4/version \
    ${localstatedir}/log/hardware-init.log \
    "

PROVIDES = "raspberrypi4-init-scripts"
RPROVIDES:${PN} = "raspberrypi4-init-scripts"