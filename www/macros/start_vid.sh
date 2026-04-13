#!/bin/bash
filepath="${1%/*}"
filename="${1##*/}"
filename_no_ext="${filename%.mp4}"
filename_no_ext="au${filename_no_ext:2}"

final_path="$filepath/$filename_no_ext.wav"
tmp_path="/dev/shm/$filename_no_ext.wav"

pidfile="/tmp/fishcam_arecord.pid"
targetfile="/tmp/fishcam_audio_target"

ADEV="plughw:CARD=Device,DEV=0"

echo "[start_vid] iniciando gravação de áudio: $tmp_path"

if [ -f "$pidfile" ]; then
    oldpid="$(cat "$pidfile" 2>/dev/null)"
    if [ -n "$oldpid" ] && kill -0 "$oldpid" 2>/dev/null; then
        echo "[start_vid] finalizando processo antigo ($oldpid)"
        kill -INT "$oldpid" 2>/dev/null
        sleep 0.2
    fi
    rm -f "$pidfile"
fi

/usr/bin/arecord \
    -D "$ADEV" \
    -f S16_LE \
    -r 16000 \
    -c 1 \
    --buffer-time=500000 \
    --period-time=125000 \
    -t wav \
    "$tmp_path" &

echo $! > "$pidfile"
echo "$final_path" > "$targetfile"

echo "[start_vid] PID do arecord: $(cat "$pidfile")"

exit 0
