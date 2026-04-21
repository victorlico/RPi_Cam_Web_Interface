#!/usr/bin/env bash
set -euo pipefail

LABEL_NAME="fishcam"
MOUNT_POINT="/var/www/html/media"
FSTAB_FILE="/etc/fstab"
UDEV_RULE_FILE="/etc/udev/rules.d/99-fishcam-usb-ignore.rules"
BACKUP_SUFFIX="$(date +%Y%m%d_%H%M%S)"
TMP_FSTAB="$(mktemp)"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

err() {
  echo "[ERROR] $*" >&2
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    err "Run this script as root: sudo $0"
    exit 1
  fi
}

check_label_exists() {
  if ! blkid -t LABEL="${LABEL_NAME}" >/dev/null 2>&1; then
    err "No device with label '${LABEL_NAME}' was found."
    err "Format the USB drive as FAT32 and set its label to '${LABEL_NAME}', then plug it in and try again."
    exit 1
  fi
}

ensure_mount_point() {
  log "Ensuring mount point exists at ${MOUNT_POINT}"
  mkdir -p "${MOUNT_POINT}"
}

backup_file() {
  local file="$1"
  if [[ -f "${file}" ]]; then
    cp "${file}" "${file}.bak.${BACKUP_SUFFIX}"
    log "Backup created: ${file}.bak.${BACKUP_SUFFIX}"
  fi
}

remove_conflicting_fstab_entries() {
  log "Cleaning previous fstab entries for ${MOUNT_POINT} and LABEL=${LABEL_NAME}"
  awk -v mp="${MOUNT_POINT}" -v label="LABEL=${LABEL_NAME}" '
    /^[[:space:]]*#/ { print; next }
    NF == 0 { print; next }
    {
      if ($1 == label || $2 == mp) next
      print
    }
  ' "${FSTAB_FILE}" > "${TMP_FSTAB}"
}

append_fstab_entry() {
  cat >> "${TMP_FSTAB}" <<EOF

# fishcam external media storage
LABEL=${LABEL_NAME}  ${MOUNT_POINT}  vfat  defaults,uid=www-data,gid=www-data,fmask=113,dmask=002,nofail  0  0
EOF
  mv "${TMP_FSTAB}" "${FSTAB_FILE}"
  chmod 644 "${FSTAB_FILE}"
  log "Updated ${FSTAB_FILE}"
}

disable_automount_gnome_hint() {
  if command -v gsettings >/dev/null 2>&1; then
    warn "gsettings detected. Desktop automount may interfere with fstab mounts."
    warn "If you use a desktop session, consider disabling media automount for the active user:"
    warn "  gsettings set org.gnome.desktop.media-handling automount false"
    warn "  gsettings set org.gnome.desktop.media-handling automount-open false"
  fi
}

create_udev_rule() {
  log "Creating udev rule to prevent udisks automount for label '${LABEL_NAME}'"
  cat > "${UDEV_RULE_FILE}" <<EOF
ENV{ID_FS_LABEL}=="${LABEL_NAME}", ENV{UDISKS_IGNORE}="1"
EOF
  chmod 644 "${UDEV_RULE_FILE}"
  udevadm control --reload || true
  udevadm trigger || true
}

unmount_conflicting_mounts() {
  log "Unmounting any existing mounts for label '${LABEL_NAME}' or ${MOUNT_POINT}"

  if mountpoint -q "${MOUNT_POINT}"; then
    umount "${MOUNT_POINT}" || warn "Could not unmount ${MOUNT_POINT} cleanly"
  fi

  local devs
  devs="$(blkid -t LABEL="${LABEL_NAME}" -o device 2>/dev/null || true)"

  if [[ -n "${devs}" ]]; then
    while IFS= read -r dev; do
      [[ -z "${dev}" ]] && continue
      while IFS= read -r mp; do
        [[ -z "${mp}" ]] && continue
        if [[ "${mp}" != "${MOUNT_POINT}" ]]; then
          umount "${mp}" 2>/dev/null || true
        fi
      done < <(findmnt -rn -S "${dev}" -o TARGET 2>/dev/null || true)
    done <<< "${devs}"
  fi
}

mount_and_validate() {
  log "Mounting filesystems from ${FSTAB_FILE}"
  mount -a

  if ! mountpoint -q "${MOUNT_POINT}"; then
    err "${MOUNT_POINT} is not a mount point after mount -a."
    exit 1
  fi

  local mounted_source
  mounted_source="$(findmnt -n -o SOURCE --target "${MOUNT_POINT}" || true)"
  local mounted_fstype
  mounted_fstype="$(findmnt -n -o FSTYPE --target "${MOUNT_POINT}" || true)"

  echo
  log "Mount validation"
  echo "  Source     : ${mounted_source}"
  echo "  Mount point: ${MOUNT_POINT}"
  echo "  Filesystem : ${mounted_fstype}"
  echo

  df -h "${MOUNT_POINT}" || true
}

show_next_steps() {
  cat <<EOF

Configuration completed.

Expected validation command:
  df -h | grep media

Expected output should include something like:
  /dev/sda1  ...  /var/www/html/media

Important notes:
- This script assumes the USB drive is FAT32 and labeled '${LABEL_NAME}'.
- If you replace the USB drive, the new one must also be FAT32 and use the same label '${LABEL_NAME}'.
- Reboot is recommended after setup:
  sudo reboot

Useful validation commands:
  mount | grep "${MOUNT_POINT}"
  findmnt "${MOUNT_POINT}"
EOF
}

main() {
  require_root
  check_label_exists
  ensure_mount_point
  backup_file "${FSTAB_FILE}"
  remove_conflicting_fstab_entries
  append_fstab_entry
  disable_automount_gnome_hint
  create_udev_rule
  unmount_conflicting_mounts
  mount_and_validate
  show_next_steps
}

main "$@"
