#!/bin/sh

source /etc/pdv/funcs/funcs_logs.sh

# Função para validar código de usuário (6 dígitos numéricos)
validar_codigo() {
  local CODIGO="$1"
  if ! echo "$CODIGO" | grep -E "^[0-9]{6}$" > /dev/null; then
    dialog --msgbox "O código de usuário deve conter exatamente 6 dígitos numéricos." 6 40
    return 1
  fi
  return 0
}

# Função para validar nome de usuário (somente letras)
validar_nome() {
  local NOME="$1"
  if ! echo "$NOME" | grep -E "^[a-zA-Z]+$" > /dev/null; then
    dialog --msgbox "O nome do usuário deve conter apenas letras." 6 40
    return 1
  fi
  return 0
}

# Função para validar senha (6 dígitos numéricos e diferente do código de usuário)
validar_senha() {
  local SENHA="$1"
  local CODIGO="$2"
  if ! echo "$SENHA" | grep -E "^[0-9]{6}$" > /dev/null; then
    dialog --msgbox "A senha deve conter exatamente 6 dígitos numéricos." 6 40
    return 1
  fi
  if [ "$SENHA" = "$CODIGO" ]; then
    dialog --msgbox "A senha não pode ser igual ao código do usuário." 6 40
    return 1
  fi
  return 0
}

# Função para cadastrar usuário
cadastrar_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  while true; do
    CODIGO=$(dialog --stdout --inputbox "Código do Usuário (6 dígitos numéricos):" 0 0)
    [ $? -ne 0 ] && log_funcs "Cadastro de usuário cancelado." && return
    validar_codigo "$CODIGO" && break
  done

  while true; do
    USUARIO=$(dialog --stdout --inputbox "Nome do Usuário (apenas letras):" 0 0)
    [ $? -ne 0 ] && log_funcs "Cadastro de usuário cancelado." && return
    validar_nome "$USUARIO" && break
  done

  while true; do
    SENHA=$(dialog --stdout --passwordbox "Senha do Usuário (6 dígitos numéricos):" 0 0)
    [ $? -ne 0 ] && log_funcs "Cadastro de usuário cancelado." && return
    validar_senha "$SENHA" "$CODIGO" && break
  done

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
  redis-cli -h $DB_HOST HMSET "usuario:$CODIGO" nome "$USUARIO" senha "$SENHA" role "$ROLE"
  log_funcs "Usuário $USUARIO (Código: $CODIGO) cadastrado com sucesso com a função $ROLE."

  dialog --msgbox "Usuário $USUARIO (Código: $CODIGO) cadastrado com sucesso!" 6 40
}

# Função para autenticar o usuário
autenticar_usuario() {
  ROLE_REQUERIDA="$1"

  # Solicitar o nome do usuário e a senha
  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && log_funcs "Autenticação cancelada pelo usuário." && return 1

  SENHA=$(dialog --stdout --passwordbox "Senha:" 0 0)
  [ $? -ne 0 ] && log_funcs "Autenticação cancelada pelo usuário." && return 1

  # Buscar role e senha do usuário no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" senha)

  # Verificar se a senha está correta
  if [ "$SENHA" != "$SENHA_CORRETA" ]; then
    dialog --msgbox "Senha incorreta!" 6 40
    log_funcs "Tentativa de login falhou para o usuário $USUARIO: senha incorreta."
    return 1
  fi

  # Verificar se a role do usuário corresponde à role requerida
  if [ "$ROLE" != "$ROLE_REQUERIDA" ]; then
    if [ "$ROLE_REQUERIDA" = "fiscal" ] && [ "$ROLE" = "admin" ]; then
      log_funcs "Usuário $USUARIO (admin) logado como fiscal."
      return 0
    fi
    dialog --msgbox "Acesso negado! Função requerida: $ROLE_REQUERIDA" 6 40
    log_funcs "Acesso negado ao usuário $USUARIO: função $ROLE_REQUERIDA requerida."
    return 1
  fi

  # Registrar login bem-sucedido
  log_funcs "Usuário $USUARIO logado com sucesso com a função $ROLE."
  return 0
}

# Função para excluir qualquer usuário, exceto o admin
excluir_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Código do usuário a ser excluído:" 0 0)
  [ $? -ne 0 ] && log_funcs "Exclusão de usuário cancelada." && return

  if [ "$USUARIO" = "admin" ]; then
    dialog --msgbox "O usuário 'admin' não pode ser excluído!" 6 40
    log_funcs "Tentativa de exclusão do usuário 'admin' bloqueada."
    return 1
  fi

  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  if [ -z "$ROLE" ]; then
    dialog --msgbox "Usuário não encontrado!" 6 40
    log_funcs "Tentativa de exclusão falhou: usuário $USUARIO não encontrado."
    return 1
  fi

  dialog --yesno "Deseja realmente excluir o usuário $USUARIO?" 7 40
  if [ $? -eq 0 ]; then
    redis-cli -h $DB_HOST DEL "usuario:$USUARIO"
    dialog --msgbox "Usuário $USUARIO excluído com sucesso!" 6 40
    log_funcs "Usuário $USUARIO excluído com sucesso."
  else
    dialog --msgbox "Exclusão cancelada." 6 40
    log_funcs "Exclusão de usuário $USUARIO cancelada."
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
    log_funcs "Nenhum usuário cadastrado foi encontrado."
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
      log_funcs "Consultou usuários na página $PAGINA_ATUAL."
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
