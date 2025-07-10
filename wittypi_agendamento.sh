#!/bin/bash

# codigo para pausar o loop do witty pi para backup e alteracao da rotina
# incluir em: nano ~/wittypi_agendamento.sh
# chmod +x ~/wittypi_agendamento.sh
# sudo cp ~/wittypi_agendamento.sh /usr/local/bin/wittypi_agendamento
# rodar: wittypi_agendamento status
# wittypi_agendamento pausar
# wittypi_agendamento ativar

WITTYPI_DIR=~/wittypi
SCRIPT=$WITTYPI_DIR/runScript.sh
BACKUP=$WITTYPI_DIR/runScript.sh.disabled

case "$1" in
    pausar)
        if [ -f "$SCRIPT" ]; then
            mv "$SCRIPT" "$BACKUP"
            echo "✅ Agendamento da Witty Pi PAUSADO. Reinicie para aplicar."
        else
            echo "⚠️ O agendamento já estava pausado."
        fi
        ;;
    ativar)
        if [ -f "$BACKUP" ]; then
            mv "$BACKUP" "$SCRIPT"
            echo "✅ Agendamento da Witty Pi ATIVADO. Reinicie para aplicar."
        else
            echo "⚠️ O agendamento já estava ativado."
        fi
        ;;
    status)
        if [ -f "$SCRIPT" ]; then
            echo "🟢 Agendamento ATIVO (runScript.sh presente)."
        elif [ -f "$BACKUP" ]; then
            echo "🟡 Agendamento PAUSADO (runScript.sh renomeado)."
        else
            echo "🔴 Arquivo runScript.sh não encontrado. Pode haver um erro."
        fi
        ;;
    *)
        echo "Uso: $0 [pausar|ativar|status]"
        echo "Exemplos:"
        echo "  ./wittypi_agendamento.sh pausar   # Pausa o agendamento"
        echo "  ./wittypi_agendamento.sh ativar   # Ativa novamente"
        echo "  ./wittypi_agendamento.sh status   # Mostra o estado atual"
        ;;
esac
