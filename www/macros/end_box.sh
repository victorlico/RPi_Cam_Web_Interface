#!/bin/bash

VIDEO="$1"
LOCK="/tmp/fishcam_audio_adjust.lock"

if [ -z "$VIDEO" ]; then
    echo "[end_box] erro: sem parâmetro"
    exit 0
fi

if [ ! -f "$VIDEO" ]; then
    echo "[end_box] erro: vídeo não encontrado: $VIDEO"
    exit 0
fi

# Lock + retry curto: espera até ~2.5 s
for i in $(seq 1 5); do
    if [ ! -f "$LOCK" ]; then
        break
    fi
    echo "[end_box] lock ativo, aguardando tentativa $i..."
    sleep 0.5
done

# Se ainda estiver ocupado, sai sem travar o sistema
if [ -f "$LOCK" ]; then
    echo "[end_box] lock ainda ativo, pulando ajuste para: $VIDEO"
    exit 0
fi

touch "$LOCK"
trap 'rm -f "$LOCK"' EXIT

DIR="${VIDEO%/*}"
BASE="${VIDEO##*/}"
STEM="${BASE%.mp4}"
AUDIO="$DIR/au${STEM:2}.wav"

if [ ! -f "$AUDIO" ]; then
    echo "[end_box] áudio correspondente não encontrado: $AUDIO"
    exit 0
fi

VT=$(/usr/bin/ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$VIDEO")
AT=$(/usr/bin/ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$AUDIO")

if [ -z "$VT" ] || [ -z "$AT" ]; then
    echo "[end_box] erro ao obter duração"
    exit 0
fi

DIFF=$(awk -v v="$VT" -v a="$AT" 'BEGIN { d=v-a; if (d<0) d=-d; printf "%.3f", d }')
THRESHOLD=0.15

echo "[end_box] vídeo: $VT s"
echo "[end_box] áudio: $AT s"
echo "[end_box] diferença: $DIFF s"

DO_ADJUST=$(awk -v d="$DIFF" -v t="$THRESHOLD" 'BEGIN { if (d > t) print 1; else print 0 }')

if [ "$DO_ADJUST" -eq 0 ]; then
    echo "[end_box] diferença <= $THRESHOLD s, sem ajuste"
    exit 0
fi

TMPA="${AUDIO%.wav}_norm.wav"

# Caso 1: áudio maior que vídeo -> corta áudio
IS_AUDIO_LONGER=$(awk -v v="$VT" -v a="$AT" 'BEGIN { if (a > v) print 1; else print 0 }')

if [ "$IS_AUDIO_LONGER" -eq 1 ]; then
    echo "[end_box] áudio maior que vídeo, cortando para $VT s"

    /usr/bin/ffmpeg -y \
        -i "$AUDIO" \
        -t "$VT" \
        -c:a pcm_s16le \
        "$TMPA"

    if [ $? -eq 0 ] && [ -f "$TMPA" ]; then
        mv "$TMPA" "$AUDIO"
        echo "[end_box] áudio ajustado por corte"
    else
        rm -f "$TMPA"
        echo "[end_box] falha ao cortar áudio"
    fi

    exit 0
fi

# Caso 2: áudio menor que vídeo -> preenche com silêncio
echo "[end_box] áudio menor que vídeo, preenchendo até $VT s"

/usr/bin/ffmpeg -y \
    -i "$AUDIO" \
    -af apad \
    -t "$VT" \
    -c:a pcm_s16le \
    "$TMPA"

if [ $? -eq 0 ] && [ -f "$TMPA" ]; then
    mv "$TMPA" "$AUDIO"
    echo "[end_box] áudio ajustado com silêncio"
else
    rm -f "$TMPA"
    echo "[end_box] falha ao preencher áudio"
fi

exit 0
