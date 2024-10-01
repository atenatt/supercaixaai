#!/bin/bash

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Definir variáveis globais
TOTAL_VENDA=0
ITENS_VENDA=()
OPERADOR=""
HORARIO=$(date '+%d/%m %H:%M:%S')
DB_HOST="redis_db"
NOME_OPERADOR=""
LOG_FILE="/tmp/pdv_log.txt"
MODO="produto"  # Variável para controlar o fluxo entre produto e quantidade
CODIGO_PRODUTO=""
NOME_PRODUTO=""
PRECO_PRODUTO=0

# Variáveis para o pagamento
VALOR_RESTANTE=0
METODOS_PAGAMENTO=()
PAGAMENTOS=()

# Função para registrar logs
registrar_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Operador: $1 | Ação: $2 | Detalhes: $3" >> "$LOG_FILE"
}

# Função para desenhar a interface conforme a imagem fornecida
desenhar_interface() {
  clear
  local mensagem="$1"

  # Definir o número total de linhas reservadas para os itens
  NUM_LINHAS_ITENS=20

  # Montar a lista de itens como uma string com quebras de linha
  ITENS_VENDA_STR=""
  for item in "${ITENS_VENDA[@]}"; do
    ITENS_VENDA_STR+="$item\n"
  done

  # Calcular o número de itens já adicionados
  NUM_ITENS=${#ITENS_VENDA[@]}

  # Calcular o número de linhas vazias restantes
  NUM_LINHAS_VAZIAS=$((NUM_LINHAS_ITENS - NUM_ITENS))

  # Criar as linhas vazias
  LINHAS_VAZIAS=""
  for ((i=0; i<NUM_LINHAS_VAZIAS; i++)); do
    LINHAS_VAZIAS+="\n"
  done

  # Montar o conteúdo da interface
  INPUTBOX_CONTENT="Produto              Quantidade              Valor\n"
  INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
  INPUTBOX_CONTENT+="$ITENS_VENDA_STR$LINHAS_VAZIAS"
  INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
  INPUTBOX_CONTENT+="                                                          Subtotal: R\$ $TOTAL_VENDA\n"
  INPUTBOX_CONTENT+="=========================================================================\n"
  INPUTBOX_CONTENT+="Operador: $NOME_OPERADOR                                    Horário: $HORARIO\n"
  INPUTBOX_CONTENT+="=========================================================================\n"
  INPUTBOX_CONTENT+="$mensagem"

  # Chamar o dialog com o conteúdo montado
  dialog_output=$(dialog --clear --backtitle "Vendas" \
    --title "======================= PDV =======================" \
    --inputbox "$INPUTBOX_CONTENT" \
    35 80 2>&1 1>/dev/tty)

  # Capturar o código de retorno para verificar se o usuário pressionou ESC
  retorno=$?

  # Limpar caracteres indesejados
  dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

  return $retorno
}

# Função para autenticar o operador
autenticar_operador() {
  while true; do
    # Solicitar o código do operador
    OPERADOR=$(dialog --stdout --inputbox "Digite o código do Operador:" 8 40)
    OPERADOR=$(echo "$OPERADOR" | sed 's/[^0-9]//g')  # Limpar caracteres inválidos

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

    # Solicitar a senha
    SENHA=$(dialog --stdout --passwordbox "Digite a senha do Operador:" 8 40)
    SENHA=$(echo "$SENHA" | sed 's/[^a-zA-Z0-9]//g')  # Limpar caracteres inválidos
    SENHA_CORRETA=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" senha)

    if [ "$SENHA" != "$SENHA_CORRETA" ]; then
      dialog --msgbox "Senha incorreta!" 6 40
      continue
    fi

    # Obter o nome do operador
    NOME_OPERADOR=$(redis-cli -h $DB_HOST HGET "usuario:$OPERADOR" nome)

    # Registrar o login no log e continuar
    registrar_log "$NOME_OPERADOR" "Login" "Operador $NOME_OPERADOR logado com sucesso."
    break
  done
}

# Função para capturar o código do produto e quantidade dentro da interface principal
capturar_input_produto() {
  MODO="produto"  # Inicializar o modo como "produto"
  while true; do
    if [ "$MODO" == "produto" ]; then
      # Solicitar o código do produto
      mensagem="Digite o código do produto ou pressione ESC para opções:"
      desenhar_interface "$mensagem"
      retorno=$?
      INPUT="$dialog_output"

      # Se o operador pressionar ESC, mostrar o menu de opções
      if [ $retorno -ne 0 ]; then
        menu_apos_esc
        continue  # Volta ao loop principal após o menu
      fi

      # Verificar se o código do produto é válido
      CODIGO_PRODUTO=$(echo "$INPUT" | sed 's/[^0-9]//g')
      if [ -z "$CODIGO_PRODUTO" ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Código de produto inválido: $INPUT"
        continue
      fi

      # Verificar se o produto existe no Redis
      NOME_PRODUTO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" nome)
      PRECO_PRODUTO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" preco_venda)
      ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO_PRODUTO" estoque)

      if [ -z "$NOME_PRODUTO" ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Produto não encontrado: $CODIGO_PRODUTO"
        continue
      fi

      if [ "$ESTOQUE" -le 0 ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Produto sem estoque: $NOME_PRODUTO"
        continue
      fi

      # Produto encontrado e com estoque, mudar para o modo quantidade
      MODO="quantidade"
    elif [ "$MODO" == "quantidade" ]; then
      # Solicitar a quantidade do produto
      mensagem="Digite a quantidade para o produto $NOME_PRODUTO:"
      desenhar_interface "$mensagem"
      retorno=$?
      INPUT="$dialog_output"

      # Se o operador pressionar ESC, mostrar o menu de opções
      if [ $retorno -ne 0 ]; then
        menu_apos_esc
        continue  # Volta ao loop principal após o menu
      fi

      # Verificar se a quantidade é válida
      QUANTIDADE=$(echo "$INPUT" | sed 's/[^0-9]//g')
      if [ -z "$QUANTIDADE" ] || [ "$QUANTIDADE" -le 0 ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Quantidade inválida: $INPUT para o produto $NOME_PRODUTO"
        MODO="produto"
        continue
      fi

      if [ "$QUANTIDADE" -gt "$ESTOQUE" ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Quantidade solicitada ($QUANTIDADE) maior que o estoque ($ESTOQUE) para o produto $NOME_PRODUTO"
        MODO="produto"
        continue
      fi

      # Calcular subtotal do item
      SUBTOTAL_ITEM=$(echo "$PRECO_PRODUTO * $QUANTIDADE" | bc)
      TOTAL_VENDA=$(echo "$TOTAL_VENDA + $SUBTOTAL_ITEM" | bc)

      # Adicionar o item à lista de venda (array)
      ITEM_FORMATADO=$(printf "%-20s %-20s R\$ %-10s" "$NOME_PRODUTO" "$QUANTIDADE" "$SUBTOTAL_ITEM")
      ITENS_VENDA+=("$ITEM_FORMATADO")

      # Atualizar o estoque no Redis
      redis-cli -h $DB_HOST HINCRBY "mercadoria:$CODIGO_PRODUTO" estoque "-$QUANTIDADE"

      # Registrar a venda do item
      registrar_log "$NOME_OPERADOR" "Venda" "Produto: $NOME_PRODUTO | Quantidade: $QUANTIDADE | Subtotal: R\$ $SUBTOTAL_ITEM"

      # Resetar para o modo produto para o próximo item
      MODO="produto"
      CODIGO_PRODUTO=""
      NOME_PRODUTO=""
      PRECO_PRODUTO=0
      QUANTIDADE=0
    fi
  done
}

# Função para exibir o menu ao pressionar ESC
menu_apos_esc() {
  opcao=$(dialog --clear --backtitle "Opções" --title "Selecione uma opção" \
    --menu "Escolha uma das opções abaixo:" 15 50 3 \
    1 "Continuar Compra" \
    2 "Cancelar Compra" \
    3 "Finalizar Compra" \
    4 "Sair do PDV" \
    2>&1 1>/dev/tty)

  case $opcao in
    1)
      # Continuar compra
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu continuar a compra."
      ;;
    2)
      # Cancelar compra
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu cancelar a compra."
      cancelar_compra
      ;;
    3)
      # Finalizar compra
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu finalizar a compra."
      processar_pagamento
      ;;
    4)
      # Sair do PDV
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu sair do PDV."
      exit
      ;;
    *)
      # Qualquer outra opção, continuar compra
      registrar_log "$NOME_OPERADOR" "Opção" "Operador retornou à compra."
      ;;
  esac
}

# Função para cancelar a compra
cancelar_compra() {
  # Salvar cupom de cancelamento em /etc/pdv e /etc/pdv/cupons
  CUPOM_FILE="/etc/pdv/$(date '+%Y%m%d%H%M%S')_compra_cancelada.txt"
  CUPOM_CUPONS="/etc/pdv/cupons/$(date '+%Y%m%d%H%M%S')_compra_cancelada.txt"

  # Montar os itens para o cupom
  ITENS_CUPOM=""
  for item in "${ITENS_VENDA[@]}"; do
    ITENS_CUPOM+="$item\n"
  done

  echo -e "======================= PDV =======================\nCOMPRA CANCELADA\nProduto              Quantidade              Valor\n--------------------------------------------------------------------------\n$ITENS_CUPOM--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $HORARIO\n==================================================" > "$CUPOM_FILE"

  # Mover o cupom para o diretório /etc/pdv/cupons
  mv "$CUPOM_FILE" "$CUPOM_CUPONS"

  # Registrar no Redis
  ID_COMPRA=$(date '+%Y%m%d%H%M%S')_"$OPERADOR"
  redis-cli -h $DB_HOST HMSET "compra:$ID_COMPRA" status "cancelada" operador "$OPERADOR" total "$TOTAL_VENDA" itens "$ITENS_CUPOM"

  registrar_log "$NOME_OPERADOR" "Compra Cancelada" "Compra cancelada e cupom salvo em $CUPOM_FILE e $CUPOM_CUPONS"

  # Resetar variáveis e voltar para a tela de vendas
  TOTAL_VENDA=0
  ITENS_VENDA=()
  MODO="produto"
}

# Função para processar o pagamento
processar_pagamento() {
  VALOR_RESTANTE=$TOTAL_VENDA
  PAGAMENTOS=()

  while (( $(echo "$VALOR_RESTANTE > 0" | bc -l) )); do
    # Selecionar método de pagamento
    metodo=$(dialog --clear --backtitle "Pagamento" --title "Selecione o método de pagamento" \
      --menu "Valor restante: R\$ $VALOR_RESTANTE\nEscolha o método de pagamento:" 15 50 3 \
      1 "Dinheiro" \
      2 "Cartão" \
      3 "Pix" \
      2>&1 1>/dev/tty)

    case $metodo in
      1)
        NOME_METODO="Dinheiro"
        ;;
      2)
        NOME_METODO="Cartão"
        ;;
      3)
        NOME_METODO="Pix"
        ;;
      *)
        # Se cancelar, retornar ao menu anterior
        registrar_log "$NOME_OPERADOR" "Pagamento" "Operador cancelou o pagamento."
        return
        ;;
    esac

    # Perguntar se vai pagar o valor total ou parcial
    opcao_pagamento=$(dialog --clear --backtitle "Pagamento" --title "Opção de Pagamento" \
      --menu "Método selecionado: $NOME_METODO\nDeseja pagar o valor total ou parcial?" 15 50 2 \
      1 "Pagar valor total" \
      2 "Pagar com mais de um método" \
      2>&1 1>/dev/tty)

    if [ "$opcao_pagamento" -eq 1 ]; then
      # Pagar valor total
      PAGAMENTOS+=("$NOME_METODO:R\$ $VALOR_RESTANTE")
      VALOR_RESTANTE=0
    elif [ "$opcao_pagamento" -eq 2 ]; then
      # Pagar com mais de um método
      valor_pago=$(dialog --clear --backtitle "Pagamento" --title "Valor a Pagar" \
        --inputbox "Valor restante: R\$ $VALOR_RESTANTE\nQuanto deseja pagar com $NOME_METODO?" 10 50 2>&1 1>/dev/tty)
      valor_pago=$(echo "$valor_pago" | sed 's/[^0-9.]//g')

      # Verificar se o valor é válido
      if [ -z "$valor_pago" ] || (( $(echo "$valor_pago <= 0" | bc -l) )) || (( $(echo "$valor_pago > $VALOR_RESTANTE" | bc -l) )); then
        dialog --msgbox "Valor inválido!" 6 40
        continue
      fi

      PAGAMENTOS+=("$NOME_METODO:R\$ $valor_pago")
      VALOR_RESTANTE=$(echo "$VALOR_RESTANTE - $valor_pago" | bc)
    else
      # Opção inválida, retornar
      continue
    fi
  done

  # Finalizar a compra
  finalizar_compra
}

# Função para finalizar a compra
finalizar_compra() {
  clear
  # Montar os métodos de pagamento utilizados
  METODOS_PAGAMENTO=$(printf "%s\n" "${PAGAMENTOS[@]}")

  dialog --msgbox "Total da compra: R\$ $TOTAL_VENDA\nPagamento:\n$METODOS_PAGAMENTO\nObrigado pela compra!" 15 50
  registrar_log "$NOME_OPERADOR" "Finalizou Venda" "Total: R\$ $TOTAL_VENDA | Pagamento: $METODOS_PAGAMENTO"

  # Salvar cupom de venda em /etc/pdv/vendas
  CUPOM_FILE="/etc/pdv/vendas/$(date '+%Y%m%d%H%M%S')_cupom.txt"

  # Montar os itens para o cupom
  ITENS_CUPOM=""
  for item in "${ITENS_VENDA[@]}"; do
    ITENS_CUPOM+="$item\n"
  done

  echo -e "======================= PDV =======================\nProduto              Quantidade              Valor\n--------------------------------------------------------------------------\n$ITENS_CUPOM--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\nMétodo(s) de Pagamento:\n$METODOS_PAGAMENTO\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $HORARIO\n==================================================" > "$CUPOM_FILE"

  # Salvar cupom no Redis
  ID_COMPRA=$(date '+%Y%m%d%H%M%S')_"$OPERADOR"
  redis-cli -h $DB_HOST HMSET "compra:$ID_COMPRA" status "finalizada" operador "$OPERADOR" total "$TOTAL_VENDA" itens "$ITENS_CUPOM" pagamentos "$METODOS_PAGAMENTO"

  # Mostrar mensagem final
  dialog --msgbox "Cupom salvo em $CUPOM_FILE" 6 40
  registrar_log "$NOME_OPERADOR" "Cupom Salvo" "Cupom salvo em $CUPOM_FILE"

  # Resetar variáveis e voltar para a tela de vendas
  TOTAL_VENDA=0
  ITENS_VENDA=()
  MODO="produto"
  PAGAMENTOS=()
}

# Verificar se os diretórios de vendas e cupons existem, se não, criar
[ ! -d "/etc/pdv/vendas" ] && mkdir -p "/etc/pdv/vendas"
[ ! -d "/etc/pdv/cupons" ] && mkdir -p "/etc/pdv/cupons"

# Iniciar o log
echo "Log iniciado em $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"

# Executar o fluxo completo
autenticar_operador
capturar_input_produto
