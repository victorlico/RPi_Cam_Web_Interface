Web based interface for controlling the Raspberry Pi Camera, includes motion detection, time lapse, and image and video recording.
Current version 6.6.26
All information on this project can be found here: http://www.raspberrypi.org/forums/viewtopic.php?f=43&t=63276

The wiki page can be found here:

http://elinux.org/RPi-Cam-Web-Interface

This includes the installation instructions at the top and full technical details.
For latest change details see:

https://github.com/silvanmelchior/RPi_Cam_Web_Interface/commits/master
  
This version has updates for php7.3 / Buster. May need further changes for nginx


## Integration with Witty Pi Mini 4

These scripts allow you to manage Witty Pi's ON/OFF scheduling system manually and flexibly.

---

## 🔧 What You Get

- `wittypi_pause_loop`  
  ⛔ Immediately cancels any scheduled shutdown or startup in Witty Pi's memory, stopping the ON/OFF loop **without reboot**.

- `wittypi_reset`  
  🔁 Schedules a safe shutdown now and automatically powers the system back on in **1 minute** using Witty Pi.

---

## 📥 Installation

Run the following commands on your Raspberry Pi to create and install the scripts:

### 1. Install `wittypi_pause_loop`

```bash
sudo tee /usr/local/bin/wittypi_pause_loop > /dev/null <<'EOF'
#!/bin/bash
source ~/wittypi/utilities.sh
clear_startup_time
clear_shutdown_time
clear_alarm_flags
echo "✅ All Witty Pi alarms cleared. ON/OFF loop paused."
EOF

sudo chmod +x /usr/local/bin/wittypi_pause_loop
```

---

### 2. Install `wittypi_reset`

```bash
sudo tee /usr/local/bin/wittypi_reset > /dev/null <<'EOF'
#!/bin/bash
WITTYPI_DIR=~/wittypi
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
EOF

sudo chmod +x /usr/local/bin/wittypi_reset
```

---

## 🚀 Usage

### 🔄 Pause any scheduled shutdown/startup:

```bash
wittypi_pause_loop
```

This stops Witty Pi's current ON/OFF cycle immediately without rebooting.

---

### 🔁 Reboot with auto power-on in 1 minute:

```bash
wittypi_reset
```

This clears any existing alarms, sets the next startup to 1 minute from now, and shuts down the Raspberry Pi.

---

## ✅ Requirements

- Witty Pi installed and configured in `~/wittypi`
- `utilities.sh` must be present in `~/wittypi`
- `i2c` interface enabled and working
- Root privileges to access I2C and shutdown

---

## 📌 Notes

- You can integrate these commands into other scripts, system services, or remote control interfaces.
- Both scripts are independent and can be called any time.
- You can safely extend them with delay parameters or logging.

---

© 2025 – For use with Witty Pi 4 Mini and Raspberry Pi OS 
