#!/bin/sh

# Função para consultar mercadoria (Fiscal e Admin)
consultar_mercadoria() {
  autenticar_usuario "fiscal" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno:" 0 0)
  [ $? -ne 0 ] && return

  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$CODIGO")
  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    dialog --msgbox "Dados da Mercadoria:\n$RESULTADO" 10 50
  fi
}
