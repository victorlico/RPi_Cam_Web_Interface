#!/bin/bash

# Copyright (c) 2015, Bob Tidey
# All rights reserved.

# Redistribution and use, with or without modification, are permitted provided
# that the following conditions are met:
#    * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#    * Neither the name of the copyright holder nor the
#      names of its contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Description
# This script updates the installer for the browser-interface to control the RPi Cam. It can be run
# on any Raspberry Pi with a newly installed raspbian and enabled camera-support.
# Based on RPI_Cam_WEb_Interface installer by Silvan Melchior
# Edited by jfarcher to work with github
# Edited by slabua to support custom installation folder
# Additions by btidey, miraaz, gigpi
# Split up and refactored by Bob Tidey 


# Debug (gera update.txt)
exec 5> update.txt
BASH_XTRACEFD="5"
set -x

# Sempre executar a partir do diretório do script
cd "$(dirname "$(readlink -f "$0")")"

# Terminal colors
color_red="tput setaf 1"
color_green="tput setaf 2"
color_reset="tput sgr0"

fn_abort() {
    $color_red
    echo >&2 '
***************
*** ABORTED ***
***************
'
    echo "An error occurred. Exiting..." >&2
    $color_reset
    exit 1
}

trap 'fn_abort' 0
set -e

# -------------------------------------------------------------------
# Detecta branch atual
# -------------------------------------------------------------------
current_branch="$(git rev-parse --abbrev-ref HEAD)"

echo "Current branch: $current_branch"

# -------------------------------------------------------------------
# Garante que a branch existe no remoto
# -------------------------------------------------------------------
if ! git show-ref --verify --quiet "refs/remotes/origin/$current_branch"; then
    echo "Remote branch origin/$current_branch does not exist"
    exit 1
fi

# -------------------------------------------------------------------
# Compara HEAD local com remoto
# -------------------------------------------------------------------
git fetch origin "$current_branch"

local_commit="$(git rev-parse HEAD)"
remote_commit="$(git rev-parse "origin/$current_branch")"

printf "Branch : %s\nLocal  : %s\nRemote : %s\n" \
  "$current_branch" "$local_commit" "$remote_commit"

if [[ "$local_commit" == "$remote_commit" ]]; then
    dialog --title 'Update message' \
           --infobox "Branch '$current_branch' is already up to date." 4 55
    sleep 2
else
    dialog --title 'Update message' \
           --infobox "Updating branch '$current_branch'..." 4 55
    sleep 2

    # Atualização "appliance-style" (sem commits locais)
    git reset --hard "origin/$current_branch"

    chmod u+x *.sh 2>/dev/null || true
    chmod u+x www/macros/* 2>/dev/null || true
    chmod u+x wittypi_config/*.sh 2>/dev/null || true
fi

trap : 0

dialog --title 'Update message' --infobox 'Update finished.' 4 30
sleep 2

# -------------------------------------------------------------------
# Executa o install_and_config.sh atualizado
# -------------------------------------------------------------------
if [ ! -f "./install_and_config.sh" ]; then
    echo "ERROR: install_and_config.sh not found."
    exit 1
fi

chmod +x ./install_and_config.sh

if [ $# -eq 0 ]; then
    ./install_and_config.sh
else
    ./install_and_config.sh "$1"
fi
