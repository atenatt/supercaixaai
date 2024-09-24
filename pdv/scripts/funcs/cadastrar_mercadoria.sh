#!/bin/sh

# Função para cadastrar mercadoria
cadastrar_mercadoria() {
  autenticar_usuario "admin" || return 1

  GTIN=$(dialog --stdout --inputbox "Código GTIN da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  CODIGO_INTERNO=$(dialog --stdout --inputbox "Código Interno da Mercadoria (opcional):" 0 0)
  [ $? -ne 0 ] && return

  NOME=$(dialog --stdout --inputbox "Nome da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_CUSTO=$(dialog --stdout --inputbox "Preço de Custo:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_VENDA=$(dialog --stdout --inputbox "Preço de Venda:" 0 0)
  [ $? -ne 0 ] && return

  # Salvar no Redis usando o código GTIN como chave
  redis-cli -h $DB_HOST HMSET "mercadoria:$GTIN" gtin "$GTIN" codigo_interno "$CODIGO_INTERNO" nome "$NOME" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA"

  # Se um código interno foi fornecido, salvá-lo também
  if [ ! -z "$CODIGO_INTERNO" ]; then
    redis-cli -h $DB_HOST HMSET "mercadoria:$CODIGO_INTERNO" gtin "$GTIN" codigo_interno "$CODIGO_INTERNO" nome "$NOME" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA"
  fi

  dialog --msgbox "Mercadoria cadastrada com sucesso!" 6 40
}
