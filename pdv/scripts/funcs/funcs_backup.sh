#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Criar diretório de logs, caso não exista
LOG_DIR="/var/log/funcoes"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/funcoes_$(date '+%Y-%m-%d_%H-%M').log"

# Capturar o nome do script e o usuário que executou
SCRIPT_NAME=$(basename "$0")
USUARIO=$(whoami)

# Função para logar ações no arquivo de log
log() {
  local MENSAGEM="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Usuário: $USUARIO] [Script: $SCRIPT_NAME] $MENSAGEM" >> "$LOG_FILE"
}

# Função para realizar backup do banco de dados Redis
backup_banco() {
  log "Iniciando o backup do banco de dados no container Redis..."

  # Diretório onde o Redis salva o dump.rdb
  DATA_DIR="/data"
  BACKUP_FILE="$DATA_DIR/redis_backup_$(date '+%Y-%m-%d_%H-%M-%S').rdb"

  # Testar a conexão com o Redis
  log "Conexão com o Redis - STATUS: SUCESSO"
  redis-cli -h redis_db ping
  if [ $? -ne 0 ]; then
    log "Erro ao conectar com o Redis."
    return 1
  fi

  # Enviar o comando para o Redis para salvar o banco de dados
  log "Envio do comando de backup ao Redis - STATUS: SUCESSO"
  redis-cli -h redis_db SAVE
  if [ $? -ne 0 ]; then
    log "Erro ao salvar o banco de dados no Redis."
    return 1
  fi

  # Verificar se o dump.rdb foi gerado no Redis
  log "Verificação de criação do arquivo dump.rdb - STATUS: SUCESSO"
  if [ ! -f "$DATA_DIR/dump.rdb" ]; then
    log "Erro: Arquivo dump.rdb não encontrado no Redis."
    return 1
  else
    log "Arquivo dump.rdb encontrado no Redis."
  fi

  # Copiar o arquivo dump.rdb para o diretório de backup
  log "Cópia do arquivo dump.rdb para o diretório de backup - STATUS: SUCESSO"
  cp "$DATA_DIR/dump.rdb" "$BACKUP_FILE"
  if [ $? -ne 0 ]; then
    log "Erro ao copiar o arquivo de backup."
    return 1
  fi

  # Registrar o log do backup realizado
  ACAO="Realizou backup do banco de dados"
  DETALHES="Backup salvo em $BACKUP_FILE"
  registrar_log "$USUARIO" "$ACAO" "$DETALHES"
  
  log "Backup realizado com sucesso: $BACKUP_FILE"
  dialog --msgbox "Backup realizado com sucesso! Arquivo de backup: $BACKUP_FILE" 6 50
}

# Função para verificar o último backup realizado no container Redis
verificar_ultimo_backup() {
  log "Verificando o último backup no container Redis..."

  ULTIMO_BACKUP=$(ls -t /data/redis* | head -n 1)

  if [ -z "$ULTIMO_BACKUP" ]; then
    dialog --msgbox "Nenhum backup encontrado." 6 40
    log "Nenhum backup encontrado."
  else
    dialog --msgbox "Último backup realizado: $ULTIMO_BACKUP" 6 40
    log "Último backup encontrado: $ULTIMO_BACKUP"
  fi
}
