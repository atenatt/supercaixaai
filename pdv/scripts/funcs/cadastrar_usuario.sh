#!/bin/sh

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

  dialog --msgbox "Usuário $USUARIO cadastrado com sucesso!" 6 40
}
