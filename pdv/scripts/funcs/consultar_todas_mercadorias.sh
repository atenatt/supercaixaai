#!/bin/sh

# Função para consultar todas as mercadorias cadastradas com paginação
consultar_todas_mercadorias() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Pega todas as chaves de mercadorias cadastradas
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")

  if [ -z "$MERCADORIAS" ]; then
    dialog --msgbox "Nenhuma mercadoria cadastrada." 6 40
    return 1
  fi

  # Número de itens por página
  ITENS_POR_PAGINA=5
  TOTAL_MERCADORIAS=$(echo "$MERCADORIAS" | wc -l)
  PAGINAS=$((($TOTAL_MERCADORIAS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))

  PAGINA_ATUAL=1

  while true; do
    # Calcular o intervalo de itens a serem mostrados
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))

    # Inicializar a variável LISTAGEM para a página atual
    LISTAGEM=""

    # Loop através das mercadorias para exibir os dados
    for MERCADORIA in $(echo "$MERCADORIAS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      CODIGO=$(echo "$MERCADORIA" | cut -d: -f2)
      NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
      PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
      
      # Adicionar os detalhes da mercadoria na LISTAGEM
      if [ -n "$NOME" ] && [ -n "$PRECO_VENDA" ]; then
        LISTAGEM="$LISTAGEM\nCódigo: $CODIGO | Nome: $NOME | Preço: R$ $PRECO_VENDA"
      fi
    done

    # Verificar se a listagem está vazia
    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhuma mercadoria cadastrada na página $PAGINA_ATUAL." 6 40
    else
      # Mostrar a página de mercadorias
      dialog --msgbox "Mercadorias (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
    fi

    # Se houver mais páginas, perguntar ao usuário se quer continuar
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
