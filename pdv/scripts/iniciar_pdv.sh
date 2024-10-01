#!/bin/bash

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Definir variáveis globais
TOTAL_VENDA=0
ITENS_VENDA=""
OPERADOR=""
HORARIO=$(date '+%d-%m-%Y %H:%M:%S')
DB_HOST="redis_db"
NOME_OPERADOR=""

# Função para desenhar a interface conforme a imagem fornecida
desenhar_interface() {
  clear
  dialog_output=$(dialog --clear --backtitle "Vendas" \
    --title "======================= PDV =======================" \
    --inputbox "\
Produto              Quantidade              Valor\n\
--------------------------------------------------------------------------\n\
$ITENS_VENDA\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\
--------------------------------------------------------------------------\n\
\n\
Subtotal: R\$ $TOTAL_VENDA\n\
\n\
==================================================\n\
Operador: $NOME_OPERADOR              Horário: $HORARIO\n\
==================================================\n\
Digite o código do produto ou pressione ESC para finalizar:" \
    35 80 2>&1 1>/dev/tty)

  # Limpar caracteres indesejados, como apóstrofos e espaços extras
  dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

  echo "$dialog_output"
}

# Função para autenticar o operador diretamente com duas dialogs (uma para código e outra para senha)
autenticar_operador() {
  while true; do
    # Solicitar o código do operador
    OPERADOR=$(dialog --stdout --inputbox "Digite o código do Operador:" 8 40)
    OPERADOR=$(echo "$OPERADOR" | sed 's/[^0-9]//g')  # Limpar possíveis caracteres inválidos

    if [ -z "$OPERADOR" ]; then
      dialog --msgbox "O código do operador não pode estar vazio!" 6 40
      continue
    fi

    # Verificar se o operador existe no Redis
    OPERADOR_EXISTE=$(redis-cli -h $DB_HOST EXISTS "usuario:$OPERADOR")

    if [ "$OPERADOR_EXISTE" -ne 1 ]; then
      dialog --msgbox "Operador não encontrado!" 6 40
      continue
    fi

    # Solicitar a senha em outra dialog
    SENHA=$(dialog --stdout --passwordbox "Digite a senha do Operador:" 8 40)
    SENHA=$(echo "$SENHA" | sed 's/[^0-9]//g')  # Limpar possíveis caracteres inválidos
    SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" senha)

    if [ "$SENHA" != "$SENHA_CORRETA" ]; then
      dialog --msgbox "Senha incorreta!" 6 40
      continue
    fi

    # Obter o nome do operador para mostrar na interface de vendas
    NOME_OPERADOR=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" nome)

    # Registrar o login no log e continuar
    registrar_log "$NOME_OPERADOR" "Login" "Operador $NOME_OPERADOR logado com sucesso."
    break
  done
}

# Função para capturar o código do produto e a quantidade diretamente na interface de vendas
capturar_input_produto() {
  while true; do
    # Solicitar o código do produto na interface principal
    CODIGO_PRODUTO=$(desenhar_interface)

    # Se o operador pressionar "ESC", finalizar a compra
    if [ "$CODIGO_PRODUTO" == "ESC" ]; then
      finalizar_compra
      break
    fi

    # Verificar se o produto existe no Redis
    NOME_PRODUTO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" nome)
    PRECO_PRODUTO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" preco_venda)
    ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" estoque)

    if [ -z "$NOME_PRODUTO" ]; then
      desenhar_interface "Produto não encontrado!"
      continue
    fi

    # Solicitar a quantidade do produto na interface principal
    QUANTIDADE=$(desenhar_interface)
    if [ $? -ne 0 ]; then
      continue
    fi

    # Verificar se há estoque suficiente
    if [ "$QUANTIDADE" -gt "$ESTOQUE" ]; then
      desenhar_interface "Quantidade maior do que o disponível em estoque!"
      continue
    fi

    # Calcular subtotal do item
    SUBTOTAL_ITEM=$(echo "$PRECO_PRODUTO * $QUANTIDADE" | bc)
    TOTAL_VENDA=$(echo "$TOTAL_VENDA + $SUBTOTAL_ITEM" | bc)

    # Adicionar o item à lista de venda com espaçamento
    ITENS_VENDA+=$(printf "%-25s %-25s R\$ %-10s\n" "$NOME_PRODUTO" "$QUANTIDADE" "$SUBTOTAL_ITEM")

    # Atualizar o estoque no Redis
    redis-cli -h $DB_HOST HINCRBY "mercadoria:$CODIGO_PRODUTO" estoque -"$QUANTIDADE"

    # Adicionar o log da venda do item
    registrar_log "$NOME_OPERADOR" "Venda" "Produto: $NOME_PRODUTO, Quantidade: $QUANTIDADE, Subtotal Item: R\$ $SUBTOTAL_ITEM"
  done
}

# Função para finalizar a compra
finalizar_compra() {
  clear
  dialog --msgbox "Total da compra: R\$ $TOTAL_VENDA\nObrigado pela compra!" 10 40
  registrar_log "$NOME_OPERADOR" "Finalizou venda" "Total: R\$ $TOTAL_VENDA"
  
  # Salvar cupom de venda em /etc/pdv/vendas
  CUPOM_FILE="/etc/pdv/vendas/$(date '+%Y%m%d%H%M%S')_cupom.txt"
  echo -e "======================= PDV =======================\nProduto\t\tQuantidade\t\tValor\n--------------------------------------------------------------------------\n$ITENS_VENDA\n--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $HORARIO\n==================================================" > "$CUPOM_FILE"

  # Mostrar mensagem final
  dialog --msgbox "Cupom salvo em $CUPOM_FILE" 6 40
  exit 0
}

# Verificar se o diretório de vendas existe, se não, criar
[ ! -d "/etc/pdv/vendas" ] && mkdir -p "/etc/pdv/vendas"

# Executar o fluxo completo
autenticar_operador
capturar_input_produto
