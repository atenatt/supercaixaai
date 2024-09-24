#!/bin/sh

# Função para consultar mercadoria (Fiscal e Admin)
consultar_mercadoria() {
  # Verifica se o usuário é fiscal ou administrador
  autenticar_usuario "fiscal" || autenticar_usuario "admin" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno:" 0 0)
  [ $? -ne 0 ] && return

  # Buscar dados da mercadoria no Redis
  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$CODIGO")

  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
    PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
    ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)
    SETOR=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" setor)
    dialog --msgbox "Nome: $NOME\nPreço de Venda: R$ $PRECO_VENDA\nEstoque: $ESTOQUE\nSetor: $SETOR" 10 50
  fi
}
