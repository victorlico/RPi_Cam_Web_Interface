#!/bin/bash
# file: afterStartup.sh
#
# This script will run after Raspberry Pi boot up and finish running the schedule script.
# If you want to run your commands after boot, you can place them here.
# 
# Remarks: please use absolute path of the command, or it can not be found (by root user).
# Remarks: you may append '&' at the end of command to avoid blocking the main daemon.sh.
#
#!/bin/bash
# file: afterStartup.sh

set -eo pipefail

WITTYPI_DIR="/home/fishcam/wittypi"
FIFO="/var/www/html/FIFO"
MEDIA_PATH="/var/www/html/media"
SCHEDULE_FILE="$WITTYPI_DIR/schedule.wpi"
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
  log_local "Storage usage too high. Disabling auto restart and scheduling shutdown in +1 minute"

  DAY=$(date -d "+1 minute" "+%d")
  HOUR=$(date -d "+1 minute" "+%H")
  MINUTE=$(date -d "+1 minute" "+%M")
  SECOND=$(date -d "+1 minute" "+%S")

  clear_startup_time
  clear_shutdown_time

  CTRL2=$(i2c_read ${I2C_BUS} $I2C_MC_ADDRESS $I2C_RTC_CTRL2)
  clear_alarm_flags "$CTRL2"

  rm -f "$SCHEDULE_FILE"

  set_shutdown_time "$DAY" "$HOUR" "$MINUTE" "$SECOND"

  # extra safety
  clear_startup_time
  CTRL2=$(i2c_read ${I2C_BUS} $I2C_MC_ADDRESS $I2C_RTC_CTRL2)
  clear_alarm_flags "$CTRL2"

  log_local "Shutdown scheduled for day=$DAY time=$HOUR:$MINUTE:$SECOND with startup disabled"
}

# If schedule file does not exist, do nothing.
# This prevents manual boot from entering a shutdown loop.
if [ ! -f "$SCHEDULE_FILE" ]; then
  log_local "schedule.wpi not found. Manual/safe mode active. Exiting without starting recording."
  exit 0
fi

if [ ! -d "$MEDIA_PATH" ]; then
  log_local "ERROR: media path does not exist: $MEDIA_PATH"
  schedule_shutdown_and_disable_restart
  exit 0
fi

USAGE_PERCENT=$(df -P "$MEDIA_PATH" | awk 'NR==2 {gsub("%","",$5); print $5}')
log_local "Storage usage in $MEDIA_PATH: ${USAGE_PERCENT}%"

if [ "$USAGE_PERCENT" -ge "$MAX_USAGE_PERCENT" ]; then
  log_local "ERROR: storage usage is at or above threshold (${MAX_USAGE_PERCENT}%)"
  schedule_shutdown_and_disable_restart
  exit 0
fi

if [ ! -p "$FIFO" ]; then
  log_local "ERROR: FIFO not found at $FIFO"
  schedule_shutdown_and_disable_restart
  exit 0
fi

log_local "Storage usage OK. Starting recording with 'ca 1'"
echo "ca 1" > "$FIFO"
exit 0
