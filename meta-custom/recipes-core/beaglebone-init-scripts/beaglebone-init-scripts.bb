SUMMARY = "Custom BeagleBone hardware interface initialization scripts"
DESCRIPTION = "Scripts to initialize and configure CAN, UART, SPI, and WiFi interfaces on BeagleBone"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS:${PN} = "bash"

# Version with patch support
PV = "1.0.0"
PR = "r0"

COMPATIBLE_MACHINE = "beaglebone-yocto"

SRC_URI = " \
    file://beagle-hardware-init.sh \
    file://beagle-can-setup.sh \
    file://beagle-uart-setup.sh \
    file://beagle-spi-setup.sh \
    file://beagle-wifi-setup.sh \
    file://beagle-hardware-init.service \
    file://beagle-can-fd.patch;apply=yes \
    "

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "beagle-hardware-init.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -d ${D}${systemd_unitdir}/system
    install -d ${D}${sysconfdir}/beaglebone
    
    # Install scripts with beagle prefix
    install -m 0755 ${WORKDIR}/beagle-hardware-init.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/beagle-can-setup.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/beagle-uart-setup.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/beagle-spi-setup.sh ${D}${bindir}/
    install -m 0755 ${WORKDIR}/beagle-wifi-setup.sh ${D}${bindir}/
    
    # Install systemd service
    install -m 0644 ${WORKDIR}/beagle-hardware-init.service ${D}${systemd_unitdir}/system/
    
    # Create BeagleBone configuration directory
    echo "BeagleBone Industrial Configuration v${PV}-${PR}" > ${D}${sysconfdir}/beaglebone/version
}

FILES:${PN} += " \
    ${bindir}/beagle-hardware-init.sh \
    ${bindir}/beagle-can-setup.sh \
    ${bindir}/beagle-uart-setup.sh \
    ${bindir}/beagle-spi-setup.sh \
    ${bindir}/beagle-wifi-setup.sh \
    ${systemd_unitdir}/system/beagle-hardware-init.service \
    ${sysconfdir}/beaglebone/version \
    "

PROVIDES = "beaglebone-init-scripts"
RPROVIDES:${PN} = "beaglebone-init-scripts"