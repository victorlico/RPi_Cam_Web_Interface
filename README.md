# Fishcam  
**Web-based video and audio recording system for fish monitoring**

Fishcam is a web-based interface built on top of the RPi Cam Web Interface, designed for continuous video capture with synchronized (separate) audio recording. It supports autonomous operation using Witty Pi for scheduled power cycling.

---

## 📦 Based on

This project extends the original:

- RPi Cam Web Interface  
  http://www.raspberrypi.org/forums/viewtopic.php?f=43&t=63276  

- Wiki (installation and technical details):  
  http://elinux.org/RPi-Cam-Web-Interface  

- Original repository:  
  https://github.com/silvanmelchior/RPi_Cam_Web_Interface  

---

## 🔧 Features

### Core functionality
- Web-based control interface
- Video recording with separate audio file
- Motion detection and time-lapse (from base project)
- Automatic start/stop recording based on power events (Witty Pi)

### Custom macros

- `macros/wittypi_pause_loop`  
  ⛔ Cancels any scheduled ON/OFF loop in Witty Pi memory without reboot.

- `macros/wittypi_reset`  
  🔁 Performs a safe shutdown and schedules automatic power-on in **1 minute**.

- `macros/wittypi_read_schedule`  
  📄 Reads the current schedule (`wittypi/schedule.wpi`).

- `macros/start_vid`  
  🎙 Starts audio recording when video recording begins.

- `macros/end_vid`  
  ⏹ Stops audio recording.

- `macros/end_box`  
  🎞 Converts recorded video to `.mp4`.

---

## 📥 Installation

Run the following command on your Raspberry Pi:

```bash
./install_and_config.sh
```

⚠️ **Important:** Always use `bash` to run shell scripts (`install`, `remove`, `update`, etc.), not `sh`.

---

## Update

The system can be updated in case of a new version by executing: 

```bash
./update.sh
```
Reboot the system, them test it.

## 🚀 Usage

### External Storage

To increase storage capacity, use an external USB drive formatted as **FAT32** and labeled: `fishcam`


The system will automatically detect the drive during boot and mount it to `/var/www/html/media`.

⚠️ **Notes**
- Reboot the system after connecting a new storage device.
- Do not remove the drive while the system is powered on.

---

### System Access

1. Power on the device  
2. Wait a few minutes for initialization  
3. Connect to the same Wi-Fi network  
4. Open the following URL in a browser:

```text
http://192.168.15.25/html/
```

The preview page will appear.

<div align="center">
  <img src="img_md/preview_page.png" width="400px" alt="Preview page" />
</div>

When the system is recording, the `record video start` button changes to `record video stop` and its color also changes.

<div align="center">
  <img src="img_md/recording_button.png" width="250px" alt="Recording button state" />
</div>

---

## 🔋 Power Scheduling (Witty Pi)

Click on **`Configure power schedule`** to open the power management page.

This page allows you to configure when the system powers on and off.

<div align="center">
  <img src="img_md/power_page.png" width="250px" alt="Power schedule page" />
</div>

### Behavior

- After **POWER-UP**, a new video recording starts automatically
- Before **POWER-DOWN**, the current video recording is stopped safely

### Configuration Steps

1. Click `Pause loop` to stop all active power timers  
2. Select a preset schedule or write a custom one  
   - You can use the [Witty Pi Script Generator](https://www.uugear.com/app/wittypi-scriptgen/)  
3. Save the schedule  
4. Reboot the system and wait for the recording workflow to restart properly  

### Recording Limit

The maximum continuous video duration should be **10 minutes** by default (`video_split = 600s`).

If a recording exceeds this limit, the system will automatically split it into multiple video files.

---

## 📤 Downloading Data

There are two ways to extract recorded files.

### 1. From the Web Interface

Click on **`Download videos and images`**:

<div align="center">
  <img src="img_md/download_page.png" width="250px" alt="Download page" />
</div>

On this page, audio, video, and image files can be viewed and selected.

- Use filters if needed
- Click `Select all` to mark all files
- Click `Download selected` to generate and download a `.zip` file

### 2. Directly from the USB Drive

You can also remove the USB drive and access the files directly on another computer.

⚠️ **Important:** Only use this method when the system is **powered off**.

---

## ⚙️ System Notes

- Media path: `/var/www/html/media`
- Control FIFO: `/var/www/html/FIFO`
- Designed for autonomous operation with scheduled power cycles
- Optimized for low-power hardware such as the Raspberry Pi Zero W

---

## 🧪 Tested Configuration

- Raspberry Pi Zero W  
- Raspberry Pi OS Buster  
- Witty Pi 4 Mini  

---

## 📄 Credits

This project is based on the RPi Cam Web Interface and includes custom adaptations for Fishcam operation.

© 2026 – Fishcam Project