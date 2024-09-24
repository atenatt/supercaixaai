#!/bin/sh

# Função para excluir operador
excluir_operador() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  OPERADOR=$(dialog --stdout --inputbox "Nome do Operador a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" role)

  if [ "$ROLE" != "operador" ]; then
    dialog --msgbox "Somente operadores podem ser excluídos!" 6 40
    return 1
  fi

  dialog --yesno "Deseja excluir o operador $OPERADOR?" 7 40
  if [ $? -eq 0 ]; then
    redis-cli -h $DB_HOST DEL "usuario:$OPERADOR"
    dialog --msgbox "Operador $OPERADOR excluído com sucesso!" 6 40
  else
    dialog --msgbox "Exclusão cancelada." 6 40
  fi
}
