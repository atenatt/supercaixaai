#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Função para abrir o caixa (Operador e Fiscal)
abrir_caixa() {
  # Autentica o operador e captura o nome do usuário autenticado via código
  autenticar_usuario "operador" || return 1
  USUARIO_ATUAL=$USUARIO

  # Registrar abertura do caixa no Redis
  HORA_ATUAL=$(date '+%H:%M:%S')
  redis-cli -h $DB_HOST SET "caixa:$USUARIO_ATUAL" "aberto"
  
  # Exibir mensagem de abertura com o nome e hora
  dialog --msgbox "Caixa aberto para o operador $USUARIO_ATUAL.\nHorário: $HORA_ATUAL" 6 40
  
  # Registrar log da ação de abertura de caixa
  registrar_log "$USUARIO_ATUAL" "Abriu o caixa" "Operador: $USUARIO_ATUAL às $HORA_ATUAL"
}

# Função para registrar venda
registrar_venda() {
  # Verificar se o caixa está aberto
  CAIXA_ABERTO=$(redis-cli -h $DB_HOST GET "caixa:$USUARIO_ATUAL")
  if [ "$CAIXA_ABERTO" != "aberto" ]; then
    dialog --msgbox "Caixa fechado! Por favor, abra o caixa antes de iniciar uma venda." 6 40
    return 1
  fi

  # Inicia uma nova venda (cria um ID de venda único)
  ID_VENDA=$(date '+%Y%m%d%H%M%S')
  redis-cli -h $DB_HOST SADD "venda:$ID_VENDA" "nova"

  TOTAL_VENDA=0

  while true; do
    # Solicitar o código da mercadoria
    CODIGO=$(dialog --stdout --inputbox "Código do Produto (GTIN ou Interno):" 0 0)
    [ $? -ne 0 ] && break

    # Verificar se o produto existe e exibir informações
    NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
    PRECO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
    ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)
    
    if [ -z "$NOME" ]; then
      dialog --msgbox "Produto não encontrado!" 6 40
      continue
    fi

    # Verificar se há estoque
    if [ "$ESTOQUE" -le 0 ]; then
      dialog --msgbox "Estoque insuficiente!" 6 40
      continue
    fi

    # Solicitar a quantidade e atualizar o valor total
    QUANTIDADE=$(dialog --stdout --inputbox "Quantidade:" 0 0)
    NOVO_ESTOQUE=$((ESTOQUE - QUANTIDADE))
    
    if [ "$NOVO_ESTOQUE" -lt 0 ]; then
      dialog --msgbox "Quantidade solicitada excede o estoque disponível!" 6 40
      continue
    fi

    # Adicionar o produto ao "carrinho" (Redis)
    redis-cli -h $DB_HOST HSET "venda:$ID_VENDA:produtos" "$CODIGO" "$QUANTIDADE"
    redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" estoque "$NOVO_ESTOQUE"

    # Atualizar o valor total
    TOTAL_VENDA=$(echo "$TOTAL_VENDA + ($PRECO * $QUANTIDADE)" | bc)

    dialog --msgbox "Produto adicionado: $NOME\nQuantidade: $QUANTIDADE\nValor Total: R$ $TOTAL_VENDA" 10 40
  done

  # Finalizar venda
  finalizar_venda "$ID_VENDA" "$TOTAL_VENDA"
}

# Função para finalizar venda
finalizar_venda() {
  ID_VENDA=$1
  TOTAL_VENDA=$2

  # Exibir o valor total da venda
  dialog --msgbox "Total da venda: R$ $TOTAL_VENDA" 6 40

  # Solicitar forma de pagamento
  FORMA_PAGAMENTO=$(dialog --stdout --menu "Forma de Pagamento" 0 0 0 \
    1 "Dinheiro" \
    2 "Cartão" \
    3 "Pix")

  # Registrar a venda no Redis com forma de pagamento
  redis-cli -h $DB_HOST HSET "venda:$ID_VENDA" forma_pagamento "$FORMA_PAGAMENTO"
  redis-cli -h $DB_HOST HSET "venda:$ID_VENDA" total "$TOTAL_VENDA"
  
  dialog --msgbox "Venda finalizada com sucesso!\nForma de Pagamento: $FORMA_PAGAMENTO" 6 40

  # Registrar log da ação de venda
  registrar_log "$USUARIO_ATUAL" "Finalizou venda" "ID Venda: $ID_VENDA, Total: R$ $TOTAL_VENDA, Forma de Pagamento: $FORMA_PAGAMENTO"
}

# Função para fechar o caixa (Operador e Fiscal)
fechar_caixa() {
  # Verificar se o caixa está aberto
  CAIXA_ABERTO=$(redis-cli -h $DB_HOST GET "caixa:$USUARIO_ATUAL")
  if [ "$CAIXA_ABERTO" != "aberto" ]; then
    dialog --msgbox "Caixa já está fechado!" 6 40
    return 1
  fi

  # Fechar o caixa e registrar log
  redis-cli -h $DB_HOST DEL "caixa:$USUARIO_ATUAL"
  dialog --msgbox "Caixa fechado para o operador $USUARIO_ATUAL." 6 40

  # Registrar log da ação de fechamento de caixa
  registrar_log "$USUARIO_ATUAL" "Fechou o caixa" "Operador: $USUARIO_ATUAL"
}
