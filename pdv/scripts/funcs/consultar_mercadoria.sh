#!/bin/sh

# Função para consultar mercadoria específica (Fiscal e Admin)
consultar_mercadoria() {
  autenticar_usuario "fiscal" || autenticar_usuario "admin" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno:" 0 0)
  [ $? -ne 0 ] && return

  NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
  PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
  ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

  if [ -z "$NOME" ] || [ -z "$PRECO_VENDA" ] || [ -z "$ESTOQUE" ]; then
    dialog --msgbox "Mercadoria não encontrada!" 6 40
  else
    dialog --msgbox "Código: $CODIGO\nNome: $NOME\nPreço de Venda: R$ $PRECO_VENDA\nEstoque: $ESTOQUE" 10 50
  fi
}
