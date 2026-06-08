#!/bin/bash

set -euo pipefail

echo "==============================="
echo " Iniciando instalação completa "
echo "==============================="

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

WITTYPI_CONFIG_DIR="$REPO_DIR/wittypi_config"
WWW_DIR="/var/www/html"
MACROS_DIR="$WWW_DIR/macros"

# =========================
# Helpers
# =========================

find_wittypi_dir() {
    local found=""

    for candidate in /home/*/wittypi; do
        if [ -f "$candidate/utilities.sh" ]; then
            if [ -n "$found" ]; then
                echo "ERRO: múltiplas instalações do Witty Pi encontradas:" >&2
                echo "  $found" >&2
                echo "  $candidate" >&2
                return 1
            fi

            found="$candidate"
        fi
    done

    if [ -n "$found" ]; then
        echo "$found"
        return 0
    fi

    echo "ERRO: não encontrei instalação do Witty Pi em /home/*/wittypi" >&2
    return 1
}

install_file() {
    local src="$1"
    local dst="$2"

    if [ ! -f "$src" ]; then
        echo "ERRO: arquivo de origem não encontrado: $src" >&2
        exit 1
    fi

    if [ -f "$dst" ]; then
        sudo cp "$dst" "$dst.bak.$(date '+%Y%m%d_%H%M%S')"
        echo "Backup criado: $dst.bak.*"
    fi

    sudo cp "$src" "$dst"
    sudo chmod +x "$dst"
    echo "Instalado: $dst"
}

# =========================
# 1. Executar instalação RPi-Cam
# =========================

echo "[1/4] Instalando RPi-Cam..."

chmod +x "$REPO_DIR/install.sh"
cd "$REPO_DIR"
./install.sh

# =========================
# 2. Configurar armazenamento externo
# =========================

echo "[2/4] Configurando armazenamento externo..."

chmod +x "$REPO_DIR/configure_external_storage.sh"
cd "$REPO_DIR"
./configure_external_storage.sh

# =========================
# 3. Configurar Witty Pi scripts
# =========================

echo "[3/4] Configurando Witty Pi..."

WITTYPI_DIR="$(find_wittypi_dir)"

echo "Witty Pi encontrado em: $WITTYPI_DIR"

if [ ! -d "$WITTYPI_CONFIG_DIR" ]; then
    echo "ERRO: diretório wittypi_config não encontrado em: $WITTYPI_CONFIG_DIR" >&2
    exit 1
fi

install_file "$WITTYPI_CONFIG_DIR/afterStartup.sh" "$WITTYPI_DIR/afterStartup.sh"
install_file "$WITTYPI_CONFIG_DIR/beforeShutdown.sh" "$WITTYPI_DIR/beforeShutdown.sh"

# =========================
# 4. Garantir permissões das macros Fishcam
# =========================

echo "[4/4] Ajustando permissões das macros Fishcam..."

REQUIRED_MACROS="
fishcam_apply_capture_cycle
fishcam_apply_capture_cycle_disable
fishcam_capture_worker
fishcam_safe_stop_recording
wittypi_pause_loop
wittypi_reset
wittypi_read_schedule
wittypi_write_schedule
"

for macro in $REQUIRED_MACROS; do
    if [ -f "$MACROS_DIR/$macro" ]; then
        sudo chmod +x "$MACROS_DIR/$macro"
        echo "OK: $MACROS_DIR/$macro"
    else
        echo "AVISO: macro não encontrada: $MACROS_DIR/$macro"
    fi
done

# =========================
# 5. Verificações finais
# =========================

echo "==============================="
echo " Verificações finais "
echo "==============================="

echo "afterStartup instalado:"
grep -n "fishcam_capture_worker\|Starting Fishcam capture worker\|Starting recording with 'ca 1'" "$WITTYPI_DIR/afterStartup.sh" || true

echo ""
echo "beforeShutdown instalado:"
grep -n "fishcam_safe_stop_recording\|Calling safe stop macro\|Stopping recording with 'ca 0'" "$WITTYPI_DIR/beforeShutdown.sh" || true

echo ""
echo "Arquivos Witty Pi:"
ls -l "$WITTYPI_DIR/afterStartup.sh" "$WITTYPI_DIR/beforeShutdown.sh"

echo ""
echo "==============================="
echo " Instalação e configuração OK "
echo "==============================="
echo ""
echo "IMPORTANTE:"
echo "Se aparecer 'Starting recording with ca 1' nas verificações finais,"
echo "o afterStartup ainda está antigo. O correto é aparecer fishcam_capture_worker."