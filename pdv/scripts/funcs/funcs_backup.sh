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
log() {
  local MENSAGEM="$1"
  echo "[$(date '+%d-%m-%y %H:%M:%S')] [Usuário: $USUARIO] [Script: $SCRIPT_NAME] $MENSAGEM" >> "$LOG_FILE"
}

# Função para realizar backup do banco de dados Redis
backup_banco() {
  log "Iniciando o backup do banco de dados no container Redis..."

  # Diretório onde o Redis salva o dump.rdb
  DATA_DIR="/data"
  BACKUP_FILE="$DATA_DIR/redis_backup_$(date '+%Y-%m-%d_%H-%M-%S').rdb"

  # Testar a conexão com o Redis
  log "Testando conexão com o Redis..."
  redis-cli -h redis_db ping
  if [ $? -ne 0 ]; then
    log "Erro ao conectar com o Redis."
    return 1
  fi

  log "Conexão com o Redis - STATUS: SUCESSO"

  # Enviar o comando para o Redis para salvar o banco de dados
  log "Enviando comando de backup ao Redis..."
  redis-cli -h redis_db SAVE
  if [ $? -ne 0 ]; then
    log "Erro ao salvar o banco de dados no Redis."
    return 1
  fi

  log "Comando de backup enviado ao Redis - STATUS: SUCESSO"

  # Verificar se o dump.rdb foi gerado no Redis
  log "Verificando se o arquivo dump.rdb foi criado..."
  if [ ! -f "$DATA_DIR/dump.rdb" ]; then
    log "Erro: Arquivo dump.rdb não encontrado no Redis."
    return 1
  else
    log "Arquivo dump.rdb encontrado no Redis."
  fi

  # Copiar o arquivo dump.rdb para o diretório de backup
  log "Copiando o arquivo dump.rdb para o diretório de backup..."
  cp "$DATA_DIR/dump.rdb" "$BACKUP_FILE"
  if [ $? -ne 0 ]; then
    log "Erro ao copiar o arquivo de backup."
    return 1
  fi

  log "Arquivo dump.rdb copiado com sucesso para o diretório de backup - STATUS: SUCESSO"

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
