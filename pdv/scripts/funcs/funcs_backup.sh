#!/bin/sh

# Criar diretório de logs, caso não exista
LOG_DIR="/var/log/funcoes"
if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR" || { echo "Erro ao criar o diretório de logs."; exit 1; }
fi

# Definir o arquivo de log com timestamp
LOG_FILE="$LOG_DIR/funcoes_$(date '+%Y-%m-%d_%H-%M').log"

# Capturar o nome do script e o usuário que executou
SCRIPT_NAME=$(basename "$0")
USUARIO=$(whoami)

# Função para logar ações no arquivo de log
log() {
  local MENSAGEM="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Usuário: $USUARIO] [Script: $SCRIPT_NAME] $MENSAGEM" | tee -a "$LOG_FILE"
}

# Testando a função de log para verificar se está funcionando corretamente
log "Iniciando script de verificação de funções."

# Funções de teste simples
funcao_teste() {
  log "Executando função de teste."
  # Simular alguma operação
  sleep 1
  log "Função de teste concluída."
}

# Executar a função de teste
funcao_teste

# Finalizando script
log "Script de verificação de funções finalizado."
