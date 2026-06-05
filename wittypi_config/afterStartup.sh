#!/bin/bash
# file: afterStartup.sh
#
# This script runs after Raspberry Pi boot and after Witty Pi schedule handling.
# Fishcam uses this script to check storage and start the capture worker.
#
# Remarks:
# - Use absolute paths.
# - Run long tasks in background to avoid blocking Witty Pi daemon.

set -eo pipefail

WITTYPI_DIR="~/wittypi"
FIFO="/var/www/html/FIFO"
MEDIA_PATH="/var/www/html/media"
SCHEDULE_FILE="$WITTYPI_DIR/schedule.wpi"

FISHCAM_CONF="/var/www/html/fishcam_capture.conf"
WORKER="/var/www/html/macros/fishcam_capture_worker"
SAFE_STOP="/var/www/html/macros/fishcam_safe_stop_recording"

MAX_USAGE_PERCENT=95
LOG_FILE="$WITTYPI_DIR/fishcam_startup_guard.log"

exec >>"$LOG_FILE" 2>&1

log_local() {
  echo "$(date '+%F %T') [afterStartup] $*"
}

if [ ! -f "$WITTYPI_DIR/utilities.sh" ]; then
  log_local "ERROR: utilities.sh not found at $WITTYPI_DIR/utilities.sh"
  exit 1
fi

# shellcheck source=/dev/null
source "$WITTYPI_DIR/utilities.sh"

schedule_shutdown_and_disable_restart() {
  log_local "Storage or system guard failed. Disabling auto restart and scheduling shutdown in +1 minute"

  DAY=$(date -d "+1 minute" "+%d")
  HOUR=$(date -d "+1 minute" "+%H")
  MINUTE=$(date -d "+1 minute" "+%M")
  SECOND=$(date -d "+1 minute" "+%S")

  clear_startup_time
  clear_shutdown_time

  CTRL2=$(i2c_read ${I2C_BUS} "$I2C_MC_ADDRESS" "$I2C_RTC_CTRL2")
  clear_alarm_flags "$CTRL2"

  rm -f "$SCHEDULE_FILE"

  set_shutdown_time "$DAY" "$HOUR" "$MINUTE" "$SECOND"

  # Extra safety
  clear_startup_time
  CTRL2=$(i2c_read ${I2C_BUS} "$I2C_MC_ADDRESS" "$I2C_RTC_CTRL2")
  clear_alarm_flags "$CTRL2"

  log_local "Shutdown scheduled for day=$DAY time=$HOUR:$MINUTE:$SECOND with startup disabled"
}

# --------------------------------------------------------------------
# Load Fishcam capture configuration
# --------------------------------------------------------------------

if [ ! -f "$FISHCAM_CONF" ]; then
  log_local "fishcam_capture.conf not found. Manual/safe mode active. Exiting without starting recording."
  exit 0
fi

# shellcheck source=/dev/null
source "$FISHCAM_CONF"

if [ "${FISHCAM_ENABLED:-0}" != "1" ]; then
  log_local "Fishcam capture disabled in config. Exiting without starting recording."
  exit 0
fi

log_local "Fishcam config loaded: mode=${FISHCAM_MODE:-undefined}, record=${FISHCAM_RECORD_SECONDS:-undefined}s, interval=${FISHCAM_INTERVAL_SECONDS:-undefined}s"

# --------------------------------------------------------------------
# Safety rule:
# - power_cycle mode requires schedule.wpi
# - continuous_periodic mode does not require schedule.wpi
# --------------------------------------------------------------------

if [ "${FISHCAM_MODE:-}" = "power_cycle" ] && [ ! -f "$SCHEDULE_FILE" ]; then
  log_local "schedule.wpi not found while mode=power_cycle. Manual/safe mode active. Exiting without starting recording."
  exit 0
fi

if [ "${FISHCAM_MODE:-}" != "power_cycle" ] && [ "${FISHCAM_MODE:-}" != "continuous_periodic" ]; then
  log_local "ERROR: invalid FISHCAM_MODE='${FISHCAM_MODE:-undefined}'"
  schedule_shutdown_and_disable_restart
  exit 0
fi

# --------------------------------------------------------------------
# Storage guard
# --------------------------------------------------------------------

if [ ! -d "$MEDIA_PATH" ]; then
  log_local "ERROR: media path does not exist: $MEDIA_PATH"
  schedule_shutdown_and_disable_restart
  exit 0
fi

USAGE_PERCENT=$(df -P "$MEDIA_PATH" | awk 'NR==2 {gsub("%","",$5); print $5}')
log_local "Storage usage in $MEDIA_PATH: ${USAGE_PERCENT}%"

if [ "$USAGE_PERCENT" -ge "$MAX_USAGE_PERCENT" ]; then
  log_local "ERROR: storage usage is at or above threshold (${MAX_USAGE_PERCENT}%)"

  if [ -x "$SAFE_STOP" ]; then
    log_local "Calling safe stop before shutdown"
    "$SAFE_STOP" 10 || true
  elif [ -p "$FIFO" ]; then
    log_local "Safe stop macro not found. Sending ca 0 directly."
    echo "ca 0" > "$FIFO" || true
    sleep 10
  fi

  schedule_shutdown_and_disable_restart
  exit 0
fi

# --------------------------------------------------------------------
# FIFO and worker guard
# --------------------------------------------------------------------

if [ ! -p "$FIFO" ]; then
  log_local "ERROR: FIFO not found at $FIFO"
  schedule_shutdown_and_disable_restart
  exit 0
fi

if [ ! -x "$WORKER" ]; then
  log_local "ERROR: capture worker not found or not executable: $WORKER"
  schedule_shutdown_and_disable_restart
  exit 0
fi

# Avoid duplicate workers.
if pgrep -f "$WORKER" >/dev/null; then
  log_local "Capture worker already running. Nothing to do."
  exit 0
fi

log_local "Storage usage OK. Starting Fishcam capture worker"

/usr/bin/nohup "$WORKER" >> "$LOG_FILE" 2>&1 &

log_local "afterStartup finished"
exit 0