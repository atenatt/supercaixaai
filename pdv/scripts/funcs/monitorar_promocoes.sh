#!/bin/sh

# Função para monitorar promoções e restaurar preços
monitorar_promocoes() {
  while true; do
    TEMPO_ATUAL=$(date +%s)

    # Listar todas as promoções ativas
    PROMOCOES=$(redis-cli -h $DB_HOST KEYS "promocao:*")

    for PROMOCAO in $PROMOCOES; do
      CODIGO=$(echo $PROMOCAO | cut -d':' -f2)
      DATA_EXPIRACAO=$(redis-cli -h $DB_HOST HGET "promocao:$CODIGO" expira_em)

      # Verificar se a promoção expirou
      if [ "$TEMPO_ATUAL" -ge "$DATA_EXPIRACAO" ]; then
        # Restaurar o preço original
        PRECO_ORIGINAL=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_original)
        redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" preco_venda "$PRECO_ORIGINAL"

        # Remover a promoção
        redis-cli -h $DB_HOST DEL "promocao:$CODIGO"
        redis-cli -h $DB_HOST HDEL "mercadoria:$CODIGO" preco_original

        # Registrar log da expiração
        log_funcs "admin" "Promoção expirada" "Produto: $CODIGO, Preço restaurado para $PRECO_ORIGINAL"
      fi
    done

    # Verificar promoções a cada 1 hora
    sleep 3600
  done
}

# Iniciar o monitoramento de promoções
monitorar_promocoes