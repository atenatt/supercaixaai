#!/bin/sh

# Função para registrar os testes no log de funções
registrar_teste_log() {
  MENSAGEM=$1
  STATUS=$2  # Pode ser "SUCESSO" ou "FALHA"
  DATA_HORA=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$DATA_HORA] TESTE: $MENSAGEM - STATUS: $STATUS" >> /var/log/func.logs
}

# Função para realizar backup do banco de dados Redis
backup_banco() {
  echo "Iniciando o backup do banco de dados no container Redis..."

  # Diretório onde o Redis salva o dump.rdb
  DATA_DIR="/data"

  # Nome do arquivo de backup (com a data)
  BACKUP_FILE="$DATA_DIR/redis_backup_$(date '+%Y-%m-%d_%H-%M-%S').rdb"

  # Testar a conexão com o Redis
  echo "Testando conexão com o Redis..."
  if redis-cli -h redis_db ping; then
    registrar_teste_log "Conexão com o Redis" "SUCESSO"
  else
    registrar_teste_log "Conexão com o Redis" "FALHA"
    echo "Erro ao conectar com o Redis"
    return 1
  fi

  # Enviar o comando para o Redis para salvar o banco de dados
  echo "Enviando comando de backup ao Redis..."
  if redis-cli -h redis_db SAVE; then
    registrar_teste_log "Envio do comando de backup ao Redis" "SUCESSO"
  else
    registrar_teste_log "Envio do comando de backup ao Redis" "FALHA"
    echo "Erro ao salvar o banco de dados no Redis"
    return 1
  fi

  # Verificar se o dump.rdb foi gerado no Redis
  echo "Verificando se o arquivo dump.rdb foi criado..."
  if [ ! -f "$DATA_DIR/dump.rdb" ]; then
    registrar_teste_log "Verificação de criação do arquivo dump.rdb" "FALHA"
    echo "Erro: Arquivo dump.rdb não encontrado no Redis."
    return 1
  else
    registrar_teste_log "Verificação de criação do arquivo dump.rdb" "SUCESSO"
    echo "Arquivo dump.rdb encontrado no Redis."
  fi

  # Copiar o arquivo dump.rdb para o diretório de backup
  echo "Copiando o arquivo de backup para $BACKUP_FILE..."
  if cp "$DATA_DIR/dump.rdb" "$BACKUP_FILE"; then
    registrar_teste_log "Cópia do arquivo dump.rdb para o diretório de backup" "SUCESSO"
  else
    registrar_teste_log "Cópia do arquivo dump.rdb para o diretório de backup" "FALHA"
    echo "Erro ao copiar o arquivo de backup"
    return 1
  fi

  # Registrar o log do backup realizado
  USUARIO="admin"
  ACAO="Realizou backup do banco de dados"
  DETALHES="Backup salvo em $BACKUP_FILE"
  registrar_log "$USUARIO" "$ACAO" "$DETALHES"

  echo "Backup realizado com sucesso: $BACKUP_FILE"
  dialog --msgbox "Backup realizado com sucesso! Arquivo de backup: $BACKUP_FILE" 6 50

  # Registrar no log de testes o sucesso geral do backup
  registrar_teste_log "Função de backup de banco de dados" "SUCESSO"
}

# Função para verificar o último backup realizado no container Redis
verificar_ultimo_backup() {
  echo "Verificando o último backup no container Redis..."

  # Listar os backups e pegar o mais recente
  ULTIMO_BACKUP=$(ls -t /data/redis* | head -n 1)

  # Verificar se foi encontrado um backup
  if [ -z "$ULTIMO_BACKUP" ]; then
    registrar_teste_log "Verificação do último backup" "FALHA"
    dialog --msgbox "Nenhum backup encontrado." 6 40
  else
    registrar_teste_log "Verificação do último backup" "SUCESSO"
    echo "Último backup encontrado: $ULTIMO_BACKUP"
    dialog --msgbox "Último backup realizado: $ULTIMO_BACKUP" 6 40
  fi
}
