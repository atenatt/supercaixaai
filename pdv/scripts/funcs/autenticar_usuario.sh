#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

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
