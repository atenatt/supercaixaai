#!/bin/sh

source /etc/pdv/funcs/funcs_logs.sh

# Função para realizar backup do banco de dados Redis
backup_banco() {
  log_funcs "Iniciando o backup do banco de dados no container Redis..."

  # Diretório onde o Redis salva o dump.rdb
  DATA_DIR="/data"
  BACKUP_FILE="$DATA_DIR/redis_backup_$(date '+%Y-%m-%d_%H-%M-%S').rdb"

  # Testar a conexão com o Redis
  log_funcs "Testando conexão com o Redis..."
  redis-cli -h redis_db ping
  if [ $? -ne 0 ]; then
    log_funcs "Erro ao conectar com o Redis."
    return 1
  fi

  log_funcs "Conexão com o Redis - STATUS: SUCESSO"

  # Enviar o comando para o Redis para salvar o banco de dados
  log_funcs "Enviando comando de backup ao Redis..."
  redis-cli -h redis_db SAVE
  if [ $? -ne 0 ]; then
    log_funcs "Erro ao salvar o banco de dados no Redis."
    return 1
  fi

  log_funcs "Comando de backup enviado ao Redis - STATUS: SUCESSO"

  # Verificar se o dump.rdb foi gerado no Redis
  log_funcs "Verificando se o arquivo dump.rdb foi criado..."
  if [ ! -f "$DATA_DIR/dump.rdb" ]; then
    log_funcs "Erro: Arquivo dump.rdb não encontrado no Redis."
    return 1
  else
    log_funcs "Arquivo dump.rdb encontrado no Redis."
  fi

  # Copiar o arquivo dump.rdb para o diretório de backup
  log_funcs "Copiando o arquivo dump.rdb para o diretório de backup..."
  cp "$DATA_DIR/dump.rdb" "$BACKUP_FILE"
  if [ $? -ne 0 ]; then
    log_funcs "Erro ao copiar o arquivo de backup."
    return 1
  fi

  log_funcs "Arquivo dump.rdb copiado com sucesso para o diretório de backup - STATUS: SUCESSO"
  
  log_funcs "Backup realizado com sucesso: $BACKUP_FILE"
  dialog --msgbox "Backup realizado com sucesso! Arquivo de backup: $BACKUP_FILE" 6 50
}

# Função para verificar o último backup realizado no container Redis
verificar_ultimo_backup() {
  log_funcs "Verificando o último backup no container Redis..."

  ULTIMO_BACKUP=$(ls -t /data/redis* | head -n 1)

  if [ -z "$ULTIMO_BACKUP" ]; then
    dialog --msgbox "Nenhum backup encontrado." 6 40
    log_funcs "Nenhum backup encontrado."
  else
    dialog --msgbox "Último backup realizado: $ULTIMO_BACKUP" 6 40
    log_funcs "Último backup encontrado: $ULTIMO_BACKUP"
  fi
}
