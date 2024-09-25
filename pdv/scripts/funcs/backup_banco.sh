#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

# Função para realizar backup do banco de dados Redis via rede
backup_banco() {
  echo "Iniciando o backup do banco de dados no container Redis..."

  # Diretório compartilhado onde os backups serão armazenados
  BACKUP_DIR="/backup"

  # Verificar se o diretório de backup existe, caso contrário, criar
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "Diretório /backup não encontrado. Criando..."
    mkdir -p "$BACKUP_DIR" || { echo "Erro ao criar diretório de backup"; return 1; }
  else
    echo "Diretório /backup encontrado."
  fi

  # Nome do arquivo de backup (com a data)
  BACKUP_FILE="$BACKUP_DIR/redis_backup_$(date '+%Y-%m-%d_%H-%M-%S').rdb"

  # Testar a conexão com o Redis
  echo "Testando conexão com o Redis..."
  redis-cli -h redis_db ping || { echo "Erro ao conectar com o Redis"; return 1; }

  # Enviar o comando para o Redis para salvar o banco de dados
  echo "Enviando comando de backup ao Redis..."
  redis-cli -h redis_db SAVE || { echo "Erro ao salvar o banco de dados no Redis"; return 1; }

  # Verificar se o dump.rdb foi gerado no Redis
  echo "Verificando se o arquivo dump.rdb foi criado..."
  if redis-cli -h redis_db EXISTS dump.rdb; then
    echo "Arquivo dump.rdb encontrado no Redis."
  else
    echo "Erro: Arquivo dump.rdb não encontrado no Redis." 
    return 1
  fi

  # Copiar o arquivo dump.rdb do Redis para o diretório de backup compartilhado
  echo "Copiando o arquivo de backup do Redis para $BACKUP_FILE..."
  scp redis_db:/data/dump.rdb "$BACKUP_FILE" || { echo "Erro ao copiar o arquivo de backup"; return 1; }

  # Registrar o log do backup realizado
  USUARIO="admin"  # Aqui você pode ajustar para o usuário que estiver logado
  ACAO="Realizou backup do banco de dados"
  DETALHES="Backup salvo em $BACKUP_FILE"
  registrar_log "$USUARIO" "$ACAO" "$DETALHES"

  echo "Backup realizado com sucesso: $BACKUP_FILE"
  dialog --msgbox "Backup realizado com sucesso! Arquivo de backup: $BACKUP_FILE" 6 50
}
