# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "XCSoar Quickmenu"
HOMEPAGE = ""
LICENSE = "GPL-3.0-only"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/${LICENSE};md5=c79ff39f19dfec6d293b95dea7b07891"
SECTION = "base/app"

S = "${WORKDIR}"
PR = "r5"

SRC_URI =      "\
	file://openvario.xci \
"
addtask do_package_write_ipk after do_package

do_compile() {
        :
}

do_install() {
        echo "Installing ..."
        install -d ${D}${ROOT_HOME}/.xcsoar
        install -m 0755 ${S}/*.xci ${D}${ROOT_HOME}/.xcsoar/
}

FILES:${PN} = "${ROOT_HOME}/.xcsoar/*"

