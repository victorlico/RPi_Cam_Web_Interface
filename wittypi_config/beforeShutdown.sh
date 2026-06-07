#!/bin/bash
# file: beforeShutdown.sh
#
# Runs before Raspberry Pi shutdown.
# Stops Fishcam worker and sends ca 0 defensively.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WITTYPI_DIR="$SCRIPT_DIR"
LOG_FILE="$WITTYPI_DIR/fishcam_shutdown_guard.log"
SAFE_STOP="/var/www/html/macros/fishcam_safe_stop_recording"
FIFO="/var/www/html/FIFO"

FINAL_WAIT_SECONDS=20

exec >>"$LOG_FILE" 2>&1

log_local() {
  echo "$(date '+%F %T') [beforeShutdown] $*"
}

log_local "Started"

if [ -x "$SAFE_STOP" ]; then
  log_local "Calling safe stop macro"
  "$SAFE_STOP" "$FINAL_WAIT_SECONDS"
else
  log_local "WARNING: safe stop macro not found or not executable: $SAFE_STOP"

  if [ -p "$FIFO" ]; then
    log_local "Fallback: sending ca 0 directly"
    echo "ca 0" > "$FIFO"
    sleep "$FINAL_WAIT_SECONDS"
  else
    log_local "FIFO not found. Nothing to stop."
  fi
fi

log_local "Finished"
exit 0