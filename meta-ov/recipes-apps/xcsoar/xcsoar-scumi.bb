# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing xcsoar"

SRC_URI = "git://github.com/Scumi/XCSoar.git;protocol=https;branch=ov \
"

SRCREV:pn-xcsoar-scumi = "${AUTOREV}" 

require xcsoar.inc