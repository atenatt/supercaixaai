#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Função para autenticar o usuário
autenticar_usuario() {
  ROLE_REQUERIDA="$1"

  # Solicitar o nome do usuário e a senha
  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && return 1

  SENHA=$(dialog --stdout --passwordbox "Senha:" 0 0)
  [ $? -ne 0 ] && return 1

  # Buscar role e senha do usuário no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" senha)

  # Verificar se a senha está correta
  if [ "$SENHA" != "$SENHA_CORRETA" ]; then
    dialog --msgbox "Senha incorreta!" 6 40
    # Registrar tentativa de login com falha
    registrar_log "$USUARIO" "Tentativa de login falhou" "Senha incorreta"
    return 1
  fi

  # Verificar se a role do usuário corresponde à role requerida
  if [ "$ROLE" != "$ROLE_REQUERIDA" ]; then
    # Se for "admin", também deve ser permitido
    if [ "$ROLE_REQUERIDA" = "fiscal" ] && [ "$ROLE" = "admin" ]; then
      # Registrar login de admin acessando como fiscal
      registrar_log "$USUARIO" "Login como fiscal (admin)" "Acesso permitido"
      return 0
    fi
    dialog --msgbox "Acesso negado! Função requerida: $ROLE_REQUERIDA" 6 40
    # Registrar tentativa de login com falha por role incorreta
    registrar_log "$USUARIO" "Tentativa de login falhou" "Role incorreta: $ROLE_REQUERIDA requerida"
    return 1
  fi

  # Registrar login bem-sucedido
  registrar_log "$USUARIO" "Login bem-sucedido" "Role: $ROLE"

  return 0
}

# Função para cadastrar usuário
cadastrar_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && return

  SENHA=$(dialog --stdout --passwordbox "Senha do Usuário:" 0 0)
  [ $? -ne 0 ] && return

  ROLE=$(dialog --stdout --menu "Função do Usuário:" 10 50 3 \
    1 "admin" \
    2 "fiscal" \
    3 "operador")
  
  # Definir a função (role)
  case $ROLE in
    1) ROLE="admin" ;;
    2) ROLE="fiscal" ;;
    3) ROLE="operador" ;;
  esac

  # Salvar no Redis
  redis-cli -h $DB_HOST HMSET "usuario:$USUARIO" nome "$USUARIO" senha "$SENHA" role "$ROLE"

  # Registrar log da ação de cadastro de usuário
  registrar_log "admin" "Cadastrou usuário" "Nome: $USUARIO, Função: $ROLE"

  dialog --msgbox "Usuário $USUARIO cadastrado com sucesso!" 6 40
}

# Função para excluir qualquer usuário, exceto o admin
excluir_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Nome do usuário a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  # Verificar se o usuário é o admin
  if [ "$USUARIO" = "admin" ]; then
    dialog --msgbox "O usuário 'admin' não pode ser excluído!" 6 40
    # Registrar log de tentativa de exclusão do usuário admin
    registrar_log "admin" "Tentou excluir o usuário 'admin'" "Operação não permitida"
    return 1
  fi

  # Verificar se o usuário existe no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  if [ -z "$ROLE" ]; then
    dialog --msgbox "Usuário não encontrado!" 6 40
    # Registrar log de tentativa de exclusão de usuário não encontrado
    registrar_log "admin" "Tentou excluir usuário" "Usuário não encontrado: $USUARIO"
    return 1
  fi

  # Confirmar exclusão
  dialog --yesno "Deseja realmente excluir o usuário $USUARIO?" 7 40
  if [ $? -eq 0 ]; then
    # Excluir usuário do Redis
    redis-cli -h $DB_HOST DEL "usuario:$USUARIO"
    dialog --msgbox "Usuário $USUARIO excluído com sucesso!" 6 40

    # Registrar log da exclusão de usuário
    registrar_log "admin" "Excluiu usuário" "Usuário: $USUARIO, Função: $ROLE"
  else
    dialog --msgbox "Exclusão cancelada." 6 40
    # Registrar log de cancelamento de exclusão
    registrar_log "admin" "Cancelou exclusão de usuário" "Usuário: $USUARIO"
  fi
}

# Função para consultar todos os usuários cadastrados com paginação
consultar_todos_usuarios() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Pega todas as chaves de usuários cadastrados
  USUARIOS=$(redis-cli -h $DB_HOST KEYS "usuario:*")

  if [ -z "$USUARIOS" ]; then
    dialog --msgbox "Nenhum usuário cadastrado." 6 40
    return 1
  fi

  # Número de itens por página
  ITENS_POR_PAGINA=5
  TOTAL_USUARIOS=$(echo "$USUARIOS" | wc -l)
  PAGINAS=$((($TOTAL_USUARIOS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))

  PAGINA_ATUAL=1

  while true; do
    # Calcular o intervalo de itens a serem mostrados
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))

    # Inicializar a variável LISTAGEM para a página atual
    LISTAGEM=""

    # Loop através dos usuários para exibir os dados
    for USUARIO in $(echo "$USUARIOS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      NOME=$(echo "$USUARIO" | cut -d: -f2)
      ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$NOME" role)

      # Adicionar os detalhes do usuário na LISTAGEM
      if [ -n "$NOME" ] && [ -n "$ROLE" ]; then
        LISTAGEM="$LISTAGEM\nUsuário: $NOME | Role: $ROLE"
      fi
    done

    # Verificar se a listagem está vazia
    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhum usuário cadastrado na página $PAGINA_ATUAL." 6 40
    else
      # Mostrar a página de usuários
      dialog --msgbox "Usuários (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
    fi

    # Se houver mais páginas, perguntar ao usuário se quer continuar
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
