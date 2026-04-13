#!/bin/bash

pidfile="/tmp/fishcam_arecord.pid"
targetfile="/tmp/fishcam_audio_target"

echo "[end_vid] encerrando gravação de áudio"

if [ -f "$pidfile" ]; then
    pid="$(cat "$pidfile" 2>/dev/null)"

    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        echo "[end_vid] enviando SIGINT para $pid"
        kill -INT "$pid" 2>/dev/null

        for i in $(seq 1 50); do
            if ! kill -0 "$pid" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done

        if kill -0 "$pid" 2>/dev/null; then
            echo "[end_vid] fallback SIGTERM"
            kill -TERM "$pid" 2>/dev/null
        fi
    fi

    rm -f "$pidfile"
fi

if [ -f "$targetfile" ]; then
    final_path="$(cat "$targetfile" 2>/dev/null)"
    wav_name="$(basename "$final_path")"
    tmp_path="/dev/shm/$wav_name"

    if [ -f "$tmp_path" ]; then
        echo "[end_vid] movendo áudio para $final_path"
        mv "$tmp_path" "$final_path"
    else
        echo "[end_vid] aviso: arquivo temporário não encontrado"
    fi

    rm -f "$targetfile"
fi

exit 0

