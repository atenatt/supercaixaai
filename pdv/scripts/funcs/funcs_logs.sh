#!/bin/sh

# Definir o diretório base para os logs
BASE_LOG_DIR="/var/log/funcoes"

# Capturar a data e hora no formato desejado
DATA=$(date '+%d-%m-%y')
HORA=$(date '+%H:00')

# Criar a pasta do dia, caso não exista
LOG_DIR="$BASE_LOG_DIR/$DATA"
mkdir -p "$LOG_DIR"

# Definir o nome do arquivo de log com base na hora
LOG_FILE="$LOG_DIR/$HORA.log"

# Capturar o nome do script e o usuário que executou
SCRIPT_NAME=$(basename "$0")
USUARIO=$(whoami)

# Função para logar ações no arquivo de log
log_funcs() {
  local MENSAGEM="$1"
  echo "[$(date '+%d-%m-%y %H:%M:%S')] [Usuário: $USUARIO] [Script: $SCRIPT_NAME] $MENSAGEM" >> "$LOG_FILE"
}