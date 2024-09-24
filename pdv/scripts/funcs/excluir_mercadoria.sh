#!/bin/sh

# Função para excluir mercadoria (Somente Admin)
excluir_mercadoria() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  dialog --yesno "Deseja excluir a mercadoria $CODIGO?" 7 40
  [ $? -eq 0 ] || return

  redis-cli -h $DB_HOST DEL "mercadoria:$CODIGO"
  dialog --msgbox "Mercadoria excluída!" 6 40
}
