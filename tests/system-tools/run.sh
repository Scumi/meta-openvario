#!/bin/bash
# SPDX-License-Identifier: MIT
# Run with: bash tests/system-tools/run.sh (no root or device required).
set -eu

repo=$(cd "$(dirname "$0")/../.." && pwd)
bash "$repo/tests/system-tools/system-info.sh"
workspace=$(mktemp -d /tmp/ov-system-tools-test.XXXXXX)
trap 'rm -rf -- "$workspace"' EXIT
mkdir "$workspace/bin"
cp "$repo/tests/system-tools/mock-command" "$workspace/bin/mock-command"
chmod 755 "$workspace/bin/mock-command"
for name in systemctl udevadm ts_calibrate cp pidof systemd-cat; do
	ln -s mock-command "$workspace/bin/$name"
done
export PATH="$workspace/bin:$PATH"
export OV_SYSTEMCTL="$workspace/bin/systemctl"
export OV_UDEVADM="$workspace/bin/udevadm"
export OV_TS_CALIBRATE="$workspace/bin/ts_calibrate"
export OV_PIDOF="$workspace/bin/pidof"
export OV_SYSTEMD_CAT="$workspace/bin/systemd-cat"
export OV_TERMINATE_GRACE_SECONDS=1

new_case() {
	export CASE_DIRECTORY
	CASE_DIRECTORY=$(mktemp -d "$workspace/case.XXXXXX")
	export OV_RUNTIME_DIRECTORY="$CASE_DIRECTORY"
	export OV_TOUCH_DEVICE="$CASE_DIRECTORY/touch"
	export OV_ROTATE_PATH="$CASE_DIRECTORY/rotation"
	export OV_POINTERCAL_PATH="$CASE_DIRECTORY/pointercal"
	export OV_LIBINPUT_RULE_PATH="$CASE_DIRECTORY/rule"
	printf '3\n' > "$OV_ROTATE_PATH"
	printf 'original calibration\n' > "$OV_POINTERCAL_PATH"
	printf 'original rule\n' > "$OV_LIBINPUT_RULE_PATH"
	printf 'active\n' > "$CASE_DIRECTORY/service"
	touch "$OV_TOUCH_DEVICE"
}

calibrate() {
	sh "$repo/recipes-apps/ov-system-tools/files/touchscreen-calibration" \
		> "$CASE_DIRECTORY/output" 2>&1
}

new_case
calibrate
grep -q '^new calibration$' "$OV_POINTERCAL_PATH"
grep -q '^active$' "$CASE_DIRECTORY/service"
test -z "$(find "$CASE_DIRECTORY" -name '*.backup' -print)"

new_case
if FAIL_APPLY=1 calibrate; then exit 1; fi
grep -q '^original calibration$' "$OV_POINTERCAL_PATH"
grep -q '^original rule$' "$OV_LIBINPUT_RULE_PATH"
grep -q '^active$' "$CASE_DIRECTORY/service"

new_case
if FAIL_APPLY=1 FAIL_ROLLBACK=1 calibrate; then exit 1; fi
backup=$(find "$CASE_DIRECTORY" -name pointercal.backup -print)
test -n "$backup"
grep -q '^original calibration$' "$backup"
grep -q 'Recovery files:.*lost on reboot' "$CASE_DIRECTORY/output"
grep -q '^active$' "$CASE_DIRECTORY/service"

new_case
if CALIBRATION_BLOCKS=1 OV_CALIBRATION_TIMEOUT_SECONDS=1 calibrate; then exit 1; fi
grep -q 'timed out' "$CASE_DIRECTORY/output"
grep -q '^original calibration$' "$OV_POINTERCAL_PATH"
grep -q '^active$' "$CASE_DIRECTORY/service"
! kill -0 "$(cat "$CASE_DIRECTORY/child-pid")" 2>/dev/null

new_case
CALIBRATION_BLOCKS=1 sh "$repo/recipes-apps/ov-system-tools/files/touchscreen-calibration" \
	> "$CASE_DIRECTORY/output" 2>&1 &
worker=$!
for ((attempt = 0; attempt < 200; ++attempt)); do
	[ ! -e "$CASE_DIRECTORY/child-pid" ] || break
	sleep 0.01
done
test -e "$CASE_DIRECTORY/child-pid"
kill -TERM "$worker"
if wait "$worker"; then exit 1; fi
grep -q 'cancelled' "$CASE_DIRECTORY/output"
grep -q '^original calibration$' "$OV_POINTERCAL_PATH"
grep -q '^active$' "$CASE_DIRECTORY/service"
! kill -0 "$(cat "$CASE_DIRECTORY/child-pid")" 2>/dev/null

printf '%s\n' 'Touchscreen apply, rollback, recovery, timeout and cancellation passed.'
