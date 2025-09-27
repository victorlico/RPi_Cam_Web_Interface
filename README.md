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

Warning: use bash to run .sh files (install, remove, update...), not sh. 

### Configure External Media Storage (USB Drive - FAT32)

To avoid filling up the Raspberry Pi microSD card, you can configure the RPi-Cam-Web-Interface to save recordings directly to an external USB drive (pendrive or HDD).  

This setup uses **FAT32** so the drive can be easily accessed on Windows.


#### 1. Use a fixed label (recommended)
Format the USB drive as **FAT32** and give it a label (e.g., `fischcam`).  
Any USB drive formatted as FAT32 with this label will work.

---

#### 2. Identify the USB drive
Plug in the USB drive and check its information:

```bash
lsblk -f
# or
sudo blkid
```

You will see something like:

```
/dev/sda1: LABEL="fischcam" UUID="12AB-34CD" TYPE="vfat" ...
```

Take note of the **LABEL** (volume name) or the **UUID**.

---

#### 3. Edit `/etc/fstab`
Open the file:

```bash
sudo nano /etc/fstab
```

Add one of the following lines:

**Using LABEL (recommended for interchangeable drives):**
```
LABEL=fischcam  /var/www/html/media  vfat  defaults,uid=www-data,gid=www-data,fmask=113,dmask=002,nofail  0  0
```


Options explained:
- `vfat` → FAT32 filesystem type  
- `uid=www-data,gid=www-data` → allows the web server to write files  
- `fmask=113,dmask=002` → ensures files are created with `rw-rw-r--` permissions  
- `nofail` → prevents boot errors if the USB drive is missing  

---

#### 4. Test the mount
Apply the changes without reboot:

```bash
sudo mount -a
df -h | grep media
ls -la /var/www/html/media
```

You should now see the USB drive mounted as the media folder.

Reboot the system to apply changes.

---


© 2025 – For use with Witty Pi 4 Mini and Raspberry Pi OS 
