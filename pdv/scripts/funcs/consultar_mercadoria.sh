#!/bin/sh

# Função para consultar mercadoria (Fiscal e Admin)
consultar_mercadoria() {
  # Verifica se o usuário é fiscal ou administrador
  autenticar_usuario "fiscal" || autenticar_usuario "admin" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno:" 0 0)
  [ $? -ne 0 ] && return

  # Buscar dados da mercadoria no Redis
  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$CODIGO")

  # Verificar se a mercadoria foi encontrada
  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    dialog --msgbox "Dados da Mercadoria:\n$RESULTADO" 10 50
  fi
}
