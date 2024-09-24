#!/bin/sh

# Função para excluir mercadoria (Somente Admin)
excluir_mercadoria() {
  autenticar_usuario "admin" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  dialog --yesno "Deseja excluir a mercadoria $CODIGO?" 7 40
  [ $? -eq 0 ] || return

  redis-cli -h $DB_HOST DEL "mercadoria:$CODIGO"
  dialog --msgbox "Mercadoria excluída!" 6 40
}
