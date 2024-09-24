#!/bin/sh

# Função para abrir o caixa (Operador e Fiscal)
abrir_caixa() {
  autenticar_usuario "operador" || return 1
  OPERADOR=$(dialog --stdout --inputbox "Nome do Operador:" 0 0)
  [ $? -ne 0 ] && return

  redis-cli -h $DB_HOST SET "caixa:$OPERADOR" "aberto"
  dialog --msgbox "Caixa aberto para o operador $OPERADOR." 6 40
}
