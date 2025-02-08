#!/bin/bash
#filename="${1%.mp4}"  # $filepath.wav
filepath="${1%/*}"                # Obtém o diretório do arquivo
filename="${1##*/}"                # Obtém apenas o nome do arquivo
filename_no_ext="${filename%.mp4}" # Remove a extensão .mp4
filename_no_ext="au${filename_no_ext:2}" # Substitui "vi" por "au"

new_filepath="$filepath/$filename_no_ext.wav" # Novo caminho do arquivo
arecord -f S16_LE -r 48000 -c 2 $new_filepath
