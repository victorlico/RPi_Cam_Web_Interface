#!/bin/bash

set -e  # para o script se der erro

echo "==============================="
echo " Iniciando instalação completa "
echo "==============================="

# =========================
# 1. Executar instalação RPi-Cam
# =========================
echo "[1/3] Instalando RPi-Cam..."
chmod +x install.sh
./install.sh

# =========================
# 2. Configurar armazenamento externo
# =========================
echo "[2/3] Configurando armazenamento externo..."
chmod +x configure_external_storage.sh
./configure_external_storage.sh

# =========================
# 3. Configurar Witty Pi
# =========================
echo "[3/3] Configurando Witty Pi..."

BEFORE_SHUTDOWN="~/wittypi/beforeShutdown.sh"
AFTER_STARTUP="~/wittypi/afterStartup.sh"

# --- beforeShutdown.sh ---
echo "Configurando beforeShutdown.sh..."

if ! grep -q 'echo "ca 0" > /var/www/html/FIFO' "$BEFORE_SHUTDOWN"; then
    cat << 'EOF' >> "$BEFORE_SHUTDOWN"

# --- Fishcam: parar gravação antes de desligar ---
echo "ca 0" > /var/www/html/FIFO
sleep 10
EOF
fi

# --- afterStartup.sh ---
echo "Configurando afterStartup.sh..."

if ! grep -q 'echo "ca 1" > /var/www/html/FIFO' "$AFTER_STARTUP"; then
    cat << 'EOF' >> "$AFTER_STARTUP"

# --- Fishcam: iniciar gravação após boot ---
sleep 5
/bin/echo "ca 1" > /var/www/html/FIFO
EOF
fi

# Garantir permissões
chmod +x "$BEFORE_SHUTDOWN"
chmod +x "$AFTER_STARTUP"

echo "==============================="
echo " Instalação e configuração OK "
echo "==============================="