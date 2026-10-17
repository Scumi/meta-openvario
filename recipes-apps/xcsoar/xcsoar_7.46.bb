# Copyright (C) 2014 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

PR="r0"
RCONFLICTS:${PN}="xcsoar-testing"

SRC_URI = "git://github.com/XCSoar/XCSoar.git;protocol=https;branch=v7.46.x "

# Commit version for 7.46:
SRCREV = "1998c3e492634ec056d3f01718c6c339a8e5b445"

require xcsoar.inc
