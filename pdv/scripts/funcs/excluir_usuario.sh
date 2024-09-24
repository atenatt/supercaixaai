#!/bin/sh

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
    return 1
  fi

  # Verificar se o usuário existe no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  if [ -z "$ROLE" ]; then
    dialog --msgbox "Usuário não encontrado!" 6 40
    return 1
  fi

  # Confirmar exclusão
  dialog --yesno "Deseja realmente excluir o usuário $USUARIO?" 7 40
  if [ $? -eq 0 ]; then
    redis-cli -h $DB_HOST DEL "usuario:$USUARIO"
    dialog --msgbox "Usuário $USUARIO excluído com sucesso!" 6 40
  else
    dialog --msgbox "Exclusão cancelada." 6 40
  fi
}
