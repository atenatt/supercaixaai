#!/bin/sh

# Função para autenticar usuário
autenticar_usuario() {
  ROLE_REQUERIDA=$1
  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && return 1

  SENHA=$(dialog --stdout --passwordbox "Senha do Usuário:" 0 0)
  [ $? -ne 0 ] && return 1

  # Recuperar as informações do usuário no Redis
  SENHA_SALVA=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" senha)
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)

  if [ "$SENHA" = "$SENHA_SALVA" ]; then
    if [ "$ROLE_REQUERIDA" = "$ROLE" ] || [ "$ROLE_REQUERIDA" = "admin" ]; then
      return 0  # Autenticação bem-sucedida
    else
      dialog --msgbox "Acesso negado! Função requerida: $ROLE_REQUERIDA" 6 40
      return 1
    fi
  else
    dialog --msgbox "Senha incorreta!" 6 40
    return 1  # Falha na autenticação
  fi
}
