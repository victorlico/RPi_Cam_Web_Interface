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


### 3. Config `wittypi/beforeShutdown.sh' file to pause video before shutdown

Include in the file:

```bash
echo "ca 0" > /var/www/html/FIFO
sleep 10   # wait 10s for recording to end
```

TODO: avaliar se seria bom o comando de gravar apos ligar, ou se o gravar audomatico com o cortar do video apos 10min, fica melhor dentro da interface mesmo
---



© 2025 – For use with Witty Pi 4 Mini and Raspberry Pi OS 
