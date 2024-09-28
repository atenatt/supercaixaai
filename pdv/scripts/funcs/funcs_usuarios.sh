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

# Função para logar ações no arquivo de log (sem exibir no terminal)
log() {
  local MENSAGEM="$1"
  echo "[$(date '+%d-%m-%y %H:%M:%S')] [Usuário: $USUARIO] [Script: $SCRIPT_NAME] $MENSAGEM" >> "$LOG_FILE"
}

# Função para autenticar o usuário
autenticar_usuario() {
  ROLE_REQUERIDA="$1"

  # Solicitar o nome do usuário e a senha
  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && log "Autenticação cancelada pelo usuário." && return 1

  SENHA=$(dialog --stdout --passwordbox "Senha:" 0 0)
  [ $? -ne 0 ] && log "Autenticação cancelada pelo usuário." && return 1

  # Buscar role e senha do usuário no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" senha)

  # Verificar se a senha está correta
  if [ "$SENHA" != "$SENHA_CORRETA" ]; then
    dialog --msgbox "Senha incorreta!" 6 40
    log "Tentativa de login falhou para o usuário $USUARIO: senha incorreta."
    return 1
  fi

  # Verificar se a role do usuário corresponde à role requerida
  if [ "$ROLE" != "$ROLE_REQUERIDA" ]; then
    if [ "$ROLE_REQUERIDA" = "fiscal" ] && [ "$ROLE" = "admin" ]; then
      log "Usuário $USUARIO (admin) logado como fiscal."
      return 0
    fi
    dialog --msgbox "Acesso negado! Função requerida: $ROLE_REQUERIDA" 6 40
    log "Acesso negado ao usuário $USUARIO: função $ROLE_REQUERIDA requerida."
    return 1
  fi

  # Registrar login bem-sucedido
  log "Usuário $USUARIO logado com sucesso com a função $ROLE."
  return 0
}

# Função para cadastrar usuário
cadastrar_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && log "Cadastro de usuário cancelado." && return

  SENHA=$(dialog --stdout --passwordbox "Senha do Usuário:" 0 0)
  [ $? -ne 0 ] && log "Cadastro de usuário cancelado." && return

  ROLE=$(dialog --stdout --menu "Função do Usuário:" 10 50 3 \
    1 "admin" \
    2 "fiscal" \
    3 "operador")
  
  case $ROLE in
    1) ROLE="admin" ;;
    2) ROLE="fiscal" ;;
    3) ROLE="operador" ;;
  esac

  # Salvar no Redis
  redis-cli -h $DB_HOST HMSET "usuario:$USUARIO" nome "$USUARIO" senha "$SENHA" role "$ROLE"
  log "Usuário $USUARIO cadastrado com sucesso com a função $ROLE."

  dialog --msgbox "Usuário $USUARIO cadastrado com sucesso!" 6 40
}

# Função para excluir qualquer usuário, exceto o admin
excluir_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Nome do usuário a ser excluído:" 0 0)
  [ $? -ne 0 ] && log "Exclusão de usuário cancelada." && return

  if [ "$USUARIO" = "admin" ]; then
    dialog --msgbox "O usuário 'admin' não pode ser excluído!" 6 40
    log "Tentativa de exclusão do usuário 'admin' bloqueada."
    return 1
  fi

  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  if [ -z "$ROLE" ]; then
    dialog --msgbox "Usuário não encontrado!" 6 40
    log "Tentativa de exclusão falhou: usuário $USUARIO não encontrado."
    return 1
  fi

  dialog --yesno "Deseja realmente excluir o usuário $USUARIO?" 7 40
  if [ $? -eq 0 ]; then
    redis-cli -h $DB_HOST DEL "usuario:$USUARIO"
    dialog --msgbox "Usuário $USUARIO excluído com sucesso!" 6 40
    log "Usuário $USUARIO excluído com sucesso."
  else
    dialog --msgbox "Exclusão cancelada." 6 40
    log "Exclusão de usuário $USUARIO cancelada."
  fi
}

# Função para consultar todos os usuários cadastrados com paginação
consultar_todos_usuarios() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIOS=$(redis-cli -h $DB_HOST KEYS "usuario:*")

  if [ -z "$USUARIOS" ]; then
    dialog --msgbox "Nenhum usuário cadastrado." 6 40
    log "Nenhum usuário cadastrado foi encontrado."
    return 1
  fi

  ITENS_POR_PAGINA=5
  TOTAL_USUARIOS=$(echo "$USUARIOS" | wc -l)
  PAGINAS=$((($TOTAL_USUARIOS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))
  PAGINA_ATUAL=1

  while true; do
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))
    LISTAGEM=""

    for USUARIO in $(echo "$USUARIOS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      NOME=$(echo "$USUARIO" | cut -d: -f2)
      ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$NOME" role)

      if [ -n "$NOME" ] && [ -n "$ROLE" ]; then
        LISTAGEM="$LISTAGEM\nUsuário: $NOME | Role: $ROLE"
      fi
    done

    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhum usuário cadastrado na página $PAGINA_ATUAL." 6 40
    else
      dialog --msgbox "Usuários (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
      log "Consultou usuários na página $PAGINA_ATUAL."
    fi

    if [ $PAGINA_ATUAL -lt $PAGINAS ]; then
      dialog --yesno "Ver próxima página?" 7 40
      if [ $? -ne 0 ]; then
        break
      fi
      PAGINA_ATUAL=$(($PAGINA_ATUAL + 1))
    else
      break
    fi
  done
}
