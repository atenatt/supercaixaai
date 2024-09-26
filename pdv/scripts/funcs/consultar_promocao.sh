#!/bin/sh

# Função para consultar promoção de um produto
consultar_promocao() {
  CODIGO=$(dialog --stdout --inputbox "Digite o código GTIN ou Interno do produto:" 0 0)
  [ $? -ne 0 ] && return

  # Verificar se o produto tem uma promoção ativa
  PROMOCAO_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "promocao:$CODIGO")
  if [ "$PROMOCAO_EXISTENTE" -eq 0 ]; then
    dialog --msgbox "Nenhuma promoção ativa para este produto!" 6 40
    return 1
  fi

  # Buscar informações da promoção
  NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
  PRECO_PROMOCAO=$(redis-cli -h $DB_HOST HGET "promocao:$CODIGO" preco_promocional)
  DATA_EXPIRACAO=$(redis-cli -h $DB_HOST HGET "promocao:$CODIGO" expira_em)
  DATA_EXPIRACAO_FORMATADA=$(date -d @$DATA_EXPIRACAO)

  dialog --msgbox "Promoção ativa para o produto $NOME\n\nPreço Promocional: $PRECO_PROMOCAO\nExpira em: $DATA_EXPIRACAO_FORMATADA" 10 40
}
