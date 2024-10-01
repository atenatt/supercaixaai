#!/bin/bash

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Definir variáveis globais
TOTAL_VENDA=0
ITENS_VENDA=""
OPERADOR=""
HORARIO=$(date '+%d-%m-%Y %H:%M:%S')
DB_HOST="redis_db"

# Função para desenhar a interface de vendas
desenhar_interface() {
  clear
  dialog_output=$(dialog --clear --backtitle "Vendas" --title "================ PDV ================" \
    --inputbox "Produto\tQuantidade\tValor\n----------------------------------------\n$ITENS_VENDA\n----------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n========================================\nOperador: $OPERADOR Horário: $HORARIO\n========================================\n$1" 20 60 2>&1 1>/dev/tty)

  # Depuração: Mostrar entrada bruta do dialog
  #>&2 echo "Debug: dialog_output antes da limpeza: '$dialog_output'"

  # Limpar caracteres indesejados, como apóstrofos e espaços extras
  dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

  # Depuração: Mostrar o valor após a limpeza
  #>&2 echo "Debug: dialog_output depois da limpeza: '$dialog_output'"

  echo "$dialog_output"
}

# Função para autenticar o operador diretamente na interface de vendas
autenticar_operador() {
  while true; do
    # Solicitar o código do operador na interface principal
    OPERADOR=$(desenhar_interface "Digite o código do Operador:")
    #>&2 echo "Debug: Valor do Operador: '$OPERADOR'"
    #sleep 3

    # Remover possíveis caracteres inesperados ou espaços em branco
    OPERADOR=$(echo "$OPERADOR" | sed 's/[^0-9]//g')
    #>&2 echo "Debug: Valor do Operador depois de limpeza: '$OPERADOR'"

    if [ -z "$OPERADOR" ]; then
      desenhar_interface "O código do operador não pode estar vazio!"
      continue
    fi

    # Verificar se o operador existe no Redis
    OPERADOR_EXISTE=$(redis-cli -h $DB_HOST EXISTS "usuario:$OPERADOR")
    >&2 echo "Debug: Valor de OPERADOR_EXISTE = '$OPERADOR_EXISTE'"

    if [ "$OPERADOR_EXISTE" -ne 1 ]; then
      desenhar_interface "Operador não encontrado!"
      continue
    fi

    # Solicitar a senha na interface principal
    SENHA=$(desenhar_interface "Digite a senha do Operador:")
    SENHA=$(echo "$SENHA" | sed 's/[^0-9]//g')  # Limpar possíveis espaços
    SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" senha)

    >&2 echo "Debug: SENHA_CORRETA do Redis: '$SENHA_CORRETA'"

    if [ "$SENHA" != "$SENHA_CORRETA" ]; then
      desenhar_interface "Senha incorreta!"
      continue
    fi

    # Se a autenticação for bem-sucedida, sair do loop
    desenhar_interface "Operador logado com sucesso!"
    registrar_log "$OPERADOR" "Login" "Operador logado com sucesso."
    break
  done
}

# Função para capturar o código do produto e a quantidade diretamente na interface de vendas
capturar_input_produto() {
  while true; do
    # Solicitar o código do produto na interface principal
    CODIGO_PRODUTO=$(desenhar_interface "Digite o código do produto ou pressione ESC para finalizar:")

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
    QUANTIDADE=$(desenhar_interface "Digite a quantidade para o produto $NOME_PRODUTO (Estoque disponível: $ESTOQUE):")
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

    # Adicionar o item à lista de venda
    ITENS_VENDA+="$NOME_PRODUTO\t$QUANTIDADE\tR\$ $SUBTOTAL_ITEM\n"

    # Atualizar o estoque no Redis
    redis-cli -h $DB_HOST HINCRBY "mercadoria:$CODIGO_PRODUTO" estoque -"$QUANTIDADE"

    # Adicionar o log da venda do item
    registrar_log "$OPERADOR" "Venda" "Produto: $NOME_PRODUTO, Quantidade: $QUANTIDADE, Subtotal Item: R\$ $SUBTOTAL_ITEM"
  done
}

# Função para finalizar a compra
finalizar_compra() {
  clear
  dialog --msgbox "Total da compra: R\$ $TOTAL_VENDA\nObrigado pela compra!" 10 40
  registrar_log "$OPERADOR" "Finalizou venda" "Total: R\$ $TOTAL_VENDA"
  
  # Salvar cupom de venda em /etc/pdv/vendas
  CUPOM_FILE="/etc/pdv/vendas/$(date '+%Y%m%d%H%M%S')_cupom.txt"
  echo -e "================ PDV ================\nProduto\t\tQuantidade\t\tValor\n----------------------------------------\n$ITENS_VENDA\n----------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n========================================\nOperador: $OPERADOR Horário: $HORARIO\n========================================" > "$CUPOM_FILE"

  # Mostrar mensagem final
  dialog --msgbox "Cupom salvo em $CUPOM_FILE" 6 40
  exit 0
}

# Verificar se o diretório de vendas existe, se não, criar
[ ! -d "/etc/pdv/vendas" ] && mkdir -p "/etc/pdv/vendas"

# Executar o fluxo completo
autenticar_operador
capturar_input_produto
