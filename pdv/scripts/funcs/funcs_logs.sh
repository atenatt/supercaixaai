#!/bin/sh

# Função para registrar logs de ações de usuários
registrar_log() {
  USUARIO=$1
  ACAO=$2
  DETALHES=$3
  DATA_HORA=$(date "+%Y-%m-%d %H:%M:%S")
  DATA=$(date "+%Y-%m-%d")

  # Escreve a ação no arquivo de log
  echo "[$DATA_HORA] $USUARIO: $ACAO - $DETALHES" >> /var/log/supercaixaai_$DATA.log
}

# Função para consultar os logs do sistema (Somente Admin)
consultar_logs() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Verifica se o arquivo de log existe
  LOG_FILE="/var/log/supercaixaai_$(date "+%Y-%m-%d").log"
  if [ ! -f "$LOG_FILE" ]; then
    dialog --msgbox "Nenhum log disponível." 6 40
    return
  fi

  # Exibir o arquivo de log em uma caixa de texto
  dialog --textbox "$LOG_FILE" 30 120
}