#!/bin/sh

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
    return 1
  fi

  # Verificar se a role do usuário corresponde à role requerida
  if [ "$ROLE" != "$ROLE_REQUERIDA" ]; then
    # Se for "admin", também deve ser permitido
    if [ "$ROLE_REQUERIDA" = "fiscal" ] && [ "$ROLE" = "admin" ]; then
      return 0
    fi
    dialog --msgbox "Acesso negado! Função requerida: $ROLE_REQUERIDA" 6 40
    return 1
  fi

  return 0
}
