#!/bin/sh

# Função para consultar todas as mercadorias cadastradas com paginação
consultar_todas_mercadorias() {
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Pega todas as chaves de mercadorias cadastradas
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")

  if [ -z "$MERCADORIAS" ]; then
    dialog --msgbox "Nenhuma mercadoria cadastrada." 6 40
    return 1
  fi

  ITENS_POR_PAGINA=5
  TOTAL_MERCADORIAS=$(echo "$MERCADORIAS" | wc -l)
  PAGINAS=$((($TOTAL_MERCADORIAS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))

  PAGINA_ATUAL=1

  while true; do
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))

    LISTAGEM=""

    for MERCADORIA in $(echo "$MERCADORIAS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      CODIGO=$(echo "$MERCADORIA" | cut -d: -f2)
      NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
      PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
      ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

      if [ -n "$NOME" ] && [ -n "$PRECO_VENDA" ] && [ -n "$ESTOQUE" ]; then
        LISTAGEM="$LISTAGEM\nCódigo: $CODIGO | Nome: $NOME | Preço: R$ $PRECO_VENDA | Estoque: $ESTOQUE"
      fi
    done

    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhuma mercadoria encontrada na página $PAGINA_ATUAL." 6 40
    else
      dialog --msgbox "Mercadorias (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
    fi

    if [ $PAGINA_ATUAL -lt $PAGINAS ]; then
      dialog --yesno "Ver próxima página?" 7 40
      if [ $? -ne 0 ]; then
        break
      fi
      PAGINA_ATUAL=$(($PAGINA_ATUAL + 1))
    else
      break
    fi
  done
}
