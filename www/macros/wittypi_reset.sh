#!/bin/bash
WITTYPI_DIR="/home/fish_cam/wittypi" #TODO: Change TO GENERIC USER
DAY=$(date -d "+1 minute" "+%d")
HOUR=$(date -d "+1 minute" "+%H")
MINUTE=$(date -d "+1 minute" "+%M")
SECOND=$(date -d "+1 minute" "+%S")

TEMP_SCRIPT="/tmp/set_wittypi_startup.sh"
cat <<EOT > "$TEMP_SCRIPT"
#!/bin/bash
source "$WITTYPI_DIR/utilities.sh"
clear_startup_time
clear_shutdown_time
clear_alarm_flags
set_startup_time $DAY $HOUR $MINUTE $SECOND
EOT

chmod +x "$TEMP_SCRIPT"
sudo bash "$TEMP_SCRIPT"
rm "$TEMP_SCRIPT"

echo "⚠️ Shutting down... system will power back on in 1 minute."
sleep 2
sudo shutdown now
