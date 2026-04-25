#!/bin/bash
# file: beforeShutdown.sh
#
# This script will be executed after Witty Pi receives shutdown command (GPIO-4 gets pulled down).
# If you want to run your commands before turnning of your Raspberry Pi, you can place them here.
# Raspberry Pi will not shutdown until all commands here are executed.
#
# Remarks: please use absolute path of the command, or it can not be found (by root user).
# Remarks: you may append '&' at the end of command to avoid blocking the main daemon.sh.
#

set -eo pipefail

FIFO="/var/www/html/FIFO"
LOG_FILE="/home/fishcam/wittypi/fishcam_shutdown_guard.log"

exec >>"$LOG_FILE" 2>&1

log_local() {
  echo "$(date '+%F %T') [beforeShutdown] $*"
}

if [ -p "$FIFO" ]; then
  log_local "Stopping recording with 'ca 0'"
  echo "ca 0" > "$FIFO"

  # Give RPi-Cam-Web-Interface time to stop recording and finish boxing/conversion
  sleep 10
else
  log_local "FIFO not found at $FIFO. Nothing to stop."
fi

log_local "Syncing filesystem"
sync

exit 0