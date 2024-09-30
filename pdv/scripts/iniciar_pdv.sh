#!/bin/bash

# Caminho da imagem de fundo para a interface PDV
BACKGROUND_IMAGE="/etc/pdv/imgs/background.png"

# Função para iniciar a interface de venda
iniciar_venda_interface() {
  # Exibir a interface com a imagem de fundo e layout da venda
  clear
  echo -e "\e[48;5;21m"  # Definir fundo azul
  tput cup 0 0  # Posicionar o cursor no topo da tela
  echo "==================== PDV ===================="
  echo "Produto          Quantidade          Valor"
  echo "=============================================="
  echo ""  # Espaço para os produtos
  tput cup 20 0  # Posicionar o cursor para o rodapé

  # Exibir o nome do operador e o horário
  echo -e "\e[48;5;21m Operador: $OPERADOR"
  echo -e "\e[48;5;21m Horário: $(date '+%d-%m-%y %H:%M:%S')"
}

# Função para registrar a venda (interagindo com os produtos)
registrar_venda() {
  TOTAL_VENDA=0
  ID_VENDA=$(date '+%Y%m%d%H%M%S')

  while true; do
    # Exibir a interface de vendas
    iniciar_venda_interface

    # Solicitar o código do produto
    read -p "Digite o código do produto ou pressione 'F' para finalizar: " CODIGO

    # Se o usuário digitar 'F', finaliza a compra
    if [[ "$CODIGO" == "F" ]]; then
      finalizar_venda "$ID_VENDA" "$TOTAL_VENDA"
      break
    fi

    # Buscar informações do produto
    NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
    PRECO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
    ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

    if [[ -z "$NOME" ]]; then
      echo "Produto não encontrado!" && sleep 1
      continue
    fi

    # Verificar se há estoque disponível
    if [[ "$ESTOQUE" -le 0 ]]; then
      echo "Estoque insuficiente!" && sleep 1
      continue
    fi

    # Solicitar a quantidade do produto
    read -p "Digite a quantidade: " QUANTIDADE

    NOVO_ESTOQUE=$((ESTOQUE - QUANTIDADE))

    if [[ "$NOVO_ESTOQUE" -lt 0 ]]; then
      echo "Quantidade solicitada excede o estoque!" && sleep 1
      continue
    fi

    # Atualizar o estoque no Redis
    redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" estoque "$NOVO_ESTOQUE"
    redis-cli -h $DB_HOST HSET "venda:$ID_VENDA:produtos" "$CODIGO" "$QUANTIDADE"

    # Atualizar o valor total
    TOTAL_VENDA=$(echo "$TOTAL_VENDA + ($PRECO * $QUANTIDADE)" | bc)

    # Exibir as informações na interface
    tput cup 5 0  # Posicionar o cursor na linha de produtos
    echo "$NOME           $QUANTIDADE           R$ $(echo "$PRECO * $QUANTIDADE" | bc)"

    sleep 1  # Pausa para exibir o produto adicionado
  done
}

# Função para finalizar a venda
finalizar_venda() {
  ID_VENDA=$1
  TOTAL_VENDA=$2

  # Solicitar a forma de pagamento
  echo "Total da venda: R$ $TOTAL_VENDA"
  read -p "Forma de pagamento (1-Dinheiro, 2-Cartão, 3-Pix): " FORMA_PAGAMENTO

  case $FORMA_PAGAMENTO in
    1) FORMA_PAGAMENTO="Dinheiro" ;;
    2) FORMA_PAGAMENTO="Cartão" ;;
    3) FORMA_PAGAMENTO="Pix" ;;
    *) FORMA_PAGAMENTO="Desconhecido" ;;
  esac

  # Registrar a venda no Redis e exibir uma mensagem final
  redis-cli -h $DB_HOST HSET "venda:$ID_VENDA" total "$TOTAL_VENDA"
  redis-cli -h $DB_HOST HSET "venda:$ID_VENDA" forma_pagamento "$FORMA_PAGAMENTO"

  # Gerar o número do cupom e salvar o cupom
  NUMERO_CUPOM=$(date '+%Y%m%d%H%M%S')
  CUPOM_FILE="/etc/pdv/cupons/cupom_$NUMERO_CUPOM.txt"
  echo "Imprimindo cupom na impressora..."

  # Salvar cupom em um arquivo
  echo "================== CUPOM FISCAL ==================" > "$CUPOM_FILE"
  echo "Data: $(date '+%d-%m-%y %H:%M:%S')" >> "$CUPOM_FILE"
  echo "Operador: $OPERADOR" >> "$CUPOM_FILE"
  echo "===================================================" >> "$CUPOM_FILE"
  redis-cli -h $DB_HOST HGETALL "venda:$ID_VENDA:produtos" | while read -r linha; do
    echo "$linha" >> "$CUPOM_FILE"
  done
  echo "===================================================" >> "$CUPOM_FILE"
  echo "Total da venda: R$ $TOTAL_VENDA" >> "$CUPOM_FILE"
  echo "Forma de pagamento: $FORMA_PAGAMENTO" >> "$CUPOM_FILE"
  echo "===================================================" >> "$CUPOM_FILE"

  sleep 1
  echo "Cupom salvo em $CUPOM_FILE"
}

# Função principal para iniciar o PDV
iniciar_pdv() {
  while true; do
    # Solicitar o código do operador
    read -p "Digite o código do operador para abrir o caixa: " OPERADOR
    # Verificar o código e abrir o caixa
    abrir_caixa "$OPERADOR"
    registrar_venda
  done
}

# Iniciar o PDV
iniciar_pdv
