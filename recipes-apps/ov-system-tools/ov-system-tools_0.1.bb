SUMMARY = "Reusable OpenVario system maintenance tools"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://system-info"

S = "${WORKDIR}"

inherit allarch

RDEPENDS:${PN} = "busybox opkg systemd"

do_install() {
	install -d ${D}${libexecdir}/openvario
	install -m 0755 ${WORKDIR}/system-info \
		${D}${libexecdir}/openvario/system-info
}

FILES:${PN} = "${libexecdir}/openvario/system-info"
