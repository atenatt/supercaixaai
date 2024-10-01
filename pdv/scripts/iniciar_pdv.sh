#!/bin/bash

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Definir variáveis globais
TOTAL_VENDA=0
ITENS_VENDA=()
OPERADOR=""
DB_HOST="redis_db"
NOME_OPERADOR=""
LOG_FILE="/tmp/pdv_log.txt"
MODO="produto"  # Variável para controlar o fluxo entre produto e quantidade
CODIGO_PRODUTO=""
NOME_PRODUTO=""
PRECO_PRODUTO=0

# Função para registrar logs
registrar_log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Operador: $1 | Ação: $2 | Detalhes: $3" >> "$LOG_FILE"
}

# Função para desenhar a interface conforme a imagem fornecida
desenhar_interface() {
  while true; do
    clear
    local mensagem="$1"

    # Atualizar o horário atual
    HORARIO=$(date '+%d/%m %H:%M:%S')

    # Definir o número total de linhas reservadas para os itens
    NUM_LINHAS_ITENS=20

    # Montar a lista de itens como uma string com quebras de linha
    ITENS_VENDA_STR=""
    local index=1
    for item in "${ITENS_VENDA[@]}"; do
      ITENS_VENDA_STR+="$(printf "%-6s %-25s\n" "$index" "$item")\n"  # Garantindo a quebra de linha após cada item
      index=$((index + 1))
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
    INPUTBOX_CONTENT="Número  Produto              Quantidade          Valor\n"
    INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
    INPUTBOX_CONTENT+="$ITENS_VENDA_STR$LINHAS_VAZIAS"
    INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
    INPUTBOX_CONTENT+="                                                          Subtotal: R\$ $TOTAL_VENDA\n"
    INPUTBOX_CONTENT+="=========================================================================\n"
    INPUTBOX_CONTENT+="Operador: $NOME_OPERADOR                                    Horário: $HORARIO\n"
    INPUTBOX_CONTENT+="=========================================================================\n"
    INPUTBOX_CONTENT+="$mensagem"

    # Chamar o dialog com timeout para atualizar o horário em tempo real
    dialog_output=$(dialog --clear --timeout 1 --backtitle "Vendas" \
      --title "======================= PDV =======================" \
      --inputbox "$INPUTBOX_CONTENT" \
      35 80 2>&1 1>/dev/tty)

    retorno=$?

    # Se o timeout ocorrer (retorno 255), continuar o loop para atualizar o horário
    if [ $retorno -eq 255 ]; then
      continue
    fi

    # Limpar caracteres indesejados
    dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

    return $retorno
  done
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

      # Verificar o retorno do dialog (ESC retorna 1 ou 255)
      if [ $retorno -ne 0 ]; then
        # Se ESC for pressionado, abrir o menu de opções
        menu_apos_esc
        continue  # Volta ao loop principal após o menu
      fi

      # Verificar se o código do produto é válido
      CODIGO_PRODUTO=$(echo "$dialog_output" | sed 's/[^0-9]//g')
      if [ -z "$CODIGO_PRODUTO" ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Código de produto inválido: $dialog_output"
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

      # Verificar o retorno do dialog (ESC retorna 1 ou 255)
      if [ $retorno -ne 0 ]; then
        # Se ESC for pressionado, abrir o menu de opções
        menu_apos_esc
        continue  # Volta ao loop principal após o menu
      fi

      # Verificar se a quantidade é válida
      QUANTIDADE=$(echo "$dialog_output" | sed 's/[^0-9]//g')
      if [ -z "$QUANTIDADE" ] || [ "$QUANTIDADE" -le 0 ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Quantidade inválida: $dialog_output para o produto $NOME_PRODUTO"
        MODO="produto"
        continue
      fi

      if [ "$QUANTIDADE" -gt "$ESTOQUE" ]; then
        registrar_log "$NOME_OPERADOR" "Erro" "Quantidade solicitada ($QUANTIDADE) maior que o estoque ($ESTOQUE) para o produto $NOME_PRODUTO"
        MODO="produto"
        continue
      fi

      # Calcular subtotal do item
      SUBTOTAL_ITEM=$(echo "scale=2; $PRECO_PRODUTO * $QUANTIDADE" | bc)
      TOTAL_VENDA=$(echo "scale=2; $TOTAL_VENDA + $SUBTOTAL_ITEM" | bc)

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

# Função para desenhar a interface conforme a imagem fornecida
desenhar_interface() {
  while true; do
    clear
    local mensagem="$1"

    # Atualizar o horário atual
    HORARIO=$(date '+%d/%m %H:%M:%S')

    # Definir o número total de linhas reservadas para os itens
    NUM_LINHAS_ITENS=20

    # Montar a lista de itens como uma string com quebras de linha
    ITENS_VENDA_STR=""
    local index=1
    for item in "${ITENS_VENDA[@]}"; do
      ITENS_VENDA_STR+="$(printf "%-6s %-25s\n" "$index" "$item")\n"  # Garantindo a quebra de linha após cada item
      index=$((index + 1))
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
    INPUTBOX_CONTENT="Número  Produto              Quantidade          Valor\n"
    INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
    INPUTBOX_CONTENT+="$ITENS_VENDA_STR$LINHAS_VAZIAS"
    INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
    INPUTBOX_CONTENT+="                                                          Subtotal: R\$ $TOTAL_VENDA\n"
    INPUTBOX_CONTENT+="=========================================================================\n"
    INPUTBOX_CONTENT+="Operador: $NOME_OPERADOR                                    Horário: $HORARIO\n"
    INPUTBOX_CONTENT+="=========================================================================\n"
    INPUTBOX_CONTENT+="$mensagem"

    # Remover --no-cancel para permitir o botão ESC
    dialog_output=$(dialog --clear --backtitle "Vendas" \
      --title "======================= PDV =======================" \
      --inputbox "$INPUTBOX_CONTENT" \
      35 80 2>&1 1>/dev/tty)

    retorno=$?

    # Se ESC for pressionado, voltar ao menu de opções
    if [ $retorno -ne 0 ]; then
      return $retorno
    fi

    # Limpar caracteres indesejados
    dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

    return $retorno
  done
}

# Função para exibir o menu ao pressionar ESC
menu_apos_esc() {
  opcao=$(dialog --clear --backtitle "Opções" --title "Selecione uma opção" \
    --menu "Escolha uma das opções abaixo:" 15 50 5 \
    1 "Continuar Compra" \
    2 "Cancelar Compra" \
    3 "Finalizar Compra" \
    4 "Excluir Item" \
    5 "Recuperar Cupom" \
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
      # Excluir item
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu excluir um item."
      excluir_item
      ;;
    5)
      # Recuperar cupom
      registrar_log "$NOME_OPERADOR" "Opção" "Operador escolheu recuperar cupom."
      recuperar_cupom
      ;;
    *)
      # Qualquer outra opção, continuar compra
      registrar_log "$NOME_OPERADOR" "Opção" "Operador retornou à compra."
      ;;
  esac
}

# Função para recalcular o subtotal após exclusão de itens
recalcular_subtotal() {
  TOTAL_VENDA=0  # Reiniciar o subtotal
  for item in "${ITENS_VENDA[@]}"; do
    VALOR=$(echo "$item" | awk '{print $4}' | sed 's/[^0-9.]//g')
    TOTAL_VENDA=$(echo "scale=2; $TOTAL_VENDA + $VALOR" | bc)
  done
}

# Função para excluir um item
excluir_item() {
  if [ ${#ITENS_VENDA[@]} -eq 0 ]; then
    dialog --msgbox "Não há itens para excluir." 6 40
    return
  fi

  mensagem="Qual número do item você deseja excluir?"
  desenhar_interface "$mensagem"
  retorno=$?
  INPUT="$dialog_output"

  # Se o operador pressionar ESC, retorna ao menu
  if [ $retorno -ne 0 ]; then
    return
  fi

  ITEM_EXCLUIR=$(echo "$INPUT" | sed 's/[^0-9]//g')

  if [ -z "$ITEM_EXCLUIR" ] || [ "$ITEM_EXCLUIR" -le 0 ] || [ "$ITEM_EXCLUIR" -gt ${#ITENS_VENDA[@]} ]; then
    dialog --msgbox "Número do item inválido." 6 40
    return
  fi

  # Remover o item do array
  INDEX=$((ITEM_EXCLUIR - 1))

  # Obter detalhes do item para ajustar o estoque
  ITEM="${ITENS_VENDA[$INDEX]}"
  PRODUTO=$(echo "$ITEM" | awk '{print $1}')
  QUANTIDADE=$(echo "$ITEM" | awk '{print $2}')

  # Atualizar o estoque no Redis (repor o estoque)
  CODIGO_PRODUTO=$(redis-cli -h $DB_HOST --scan --pattern "mercadoria:*" | while read key; do
    nome=$(redis-cli -h $DB_HOST HGET "$key" nome)
    if [ "$nome" == "$PRODUTO" ]; then
      echo "${key##mercadoria:}"
      break
    fi
  done)
  redis-cli -h $DB_HOST HINCRBY "mercadoria:$CODIGO_PRODUTO" estoque "$QUANTIDADE"

  # Remover o item do array
  unset ITENS_VENDA[$INDEX]
  # Reindexar o array
  ITENS_VENDA=("${ITENS_VENDA[@]}")

  # Recalcular o subtotal após a exclusão
  recalcular_subtotal

  registrar_log "$NOME_OPERADOR" "Excluir Item" "Item $ITEM_EXCLUIR excluído."
}

# Função para desenhar a interface conforme a imagem fornecida
desenhar_interface() {
  clear
  local mensagem="$1"

  # Atualizar o horário atual
  HORARIO=$(date '+%d/%m %H:%M:%S')

  # Definir o número total de linhas reservadas para os itens
  NUM_LINHAS_ITENS=20

  # Montar a lista de itens como uma string com quebras de linha
  ITENS_VENDA_STR=""
  local index=1
  for item in "${ITENS_VENDA[@]}"; do
    ITENS_VENDA_STR+="$(printf "%-6s %-25s\n" "$index" "$item")\n"
    index=$((index + 1))
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
  INPUTBOX_CONTENT="Número  Produto              Quantidade          Valor\n"
  INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
  INPUTBOX_CONTENT+="$ITENS_VENDA_STR$LINHAS_VAZIAS"
  INPUTBOX_CONTENT+="--------------------------------------------------------------------------\n"
  INPUTBOX_CONTENT+="                                                          Subtotal: R\$ $TOTAL_VENDA\n"
  INPUTBOX_CONTENT+="=========================================================================\n"
  INPUTBOX_CONTENT+="Operador: $NOME_OPERADOR                                    Horário: $HORARIO\n"
  INPUTBOX_CONTENT+="=========================================================================\n"
  INPUTBOX_CONTENT+="$mensagem"

  # Exibir a interface
  dialog_output=$(dialog --clear --backtitle "Vendas" \
    --title "======================= PDV =======================" \
    --inputbox "$INPUTBOX_CONTENT" \
    35 80 2>&1 1>/dev/tty)

  retorno=$?

  # Se ESC for pressionado, voltar ao menu de opções
  if [ $retorno -ne 0 ]; then
    return $retorno
  fi

  # Limpar caracteres indesejados
  dialog_output=$(echo "$dialog_output" | sed "s/[^a-zA-Z0-9]//g")

  return $retorno
}

# Função para salvar e cancelar a compra
cancelar_compra() {
  # Gerar número de cupom com base na data/hora e operador
  NUM_CUPOM=$(date '+%Y%m%d%H%M%S')_"$OPERADOR"

  # Montar os itens para o cupom
  ITENS_CUPOM=""
  for item in "${ITENS_VENDA[@]}"; do
    # Simplesmente adicionar os itens já com os índices gerados pela venda
    ITENS_CUPOM+="$item\n"
  done

  # Se não houver itens, não deve gerar o cupom
  if [ -z "$ITENS_CUPOM" ]; then
    dialog --msgbox "Nenhum item adicionado. A compra não pode ser cancelada." 6 40
    return
  fi

  # Garantir que o diretório de cupons exista
  if [ ! -d "/etc/pdv/cupons" ]; then
    mkdir -p "/etc/pdv/cupons"
    # Verificar se o diretório foi criado com sucesso
    if [ $? -ne 0 ]; then
      dialog --msgbox "Erro ao criar o diretório de cupons. Verifique as permissões." 6 40
      return
    fi
  fi

  # Salvar cupom de cancelamento em /etc/pdv/cupons com o nome correto
  CUPOM_CUPONS="/etc/pdv/cupons/${NUM_CUPOM}_compra_cancelada.txt"

  # Montar o conteúdo do cupom com as quebras de linha adequadas
  echo -e "======================= PDV =======================\nCUPOM: $NUM_CUPOM\nCOMPRA CANCELADA\nNúmero  Produto              Quantidade          Valor\n--------------------------------------------------------------------------\n$ITENS_CUPOM--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $(date '+%d/%m %H:%M:%S')\n==================================================" > "$CUPOM_CUPONS"

  # Verificar se o arquivo foi criado corretamente
  if [ ! -f "$CUPOM_CUPONS" ]; then
    dialog --msgbox "Erro ao salvar o cupom. Verifique as permissões do diretório." 6 40
    return
  fi

  # Registrar no Redis com as quebras de linha apropriadas para garantir a formatação ao recuperar
  redis-cli -h $DB_HOST HMSET "compra:$NUM_CUPOM" status "cancelada" operador "$OPERADOR" total "$TOTAL_VENDA" itens "$(echo "$ITENS_CUPOM" | sed ':a;N;$!ba;s/\n/\\n/g')"

  registrar_log "$NOME_OPERADOR" "Compra Cancelada" "Compra cancelada e cupom salvo em $CUPOM_CUPONS"

  # Resetar variáveis e voltar para a tela de vendas
  TOTAL_VENDA=0
  ITENS_VENDA=()
  MODO="produto"

  # Exibir mensagem com o número do cupom cancelado
  dialog --msgbox "Compra cancelada com sucesso.\nNúmero do cupom: $NUM_CUPOM" 6 50
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
      VALOR_RESTANTE=$(echo "scale=2; $VALOR_RESTANTE - $valor_pago" | bc)
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
  # Gerar número de cupom
  NUM_CUPOM=$(date '+%Y%m%d%H%M%S')_"$OPERADOR"

  # Montar os métodos de pagamento utilizados
  METODOS_PAGAMENTO=$(printf "%s\n" "${PAGAMENTOS[@]}")

  dialog --msgbox "Total da compra: R\$ $TOTAL_VENDA\nPagamento:\n$METODOS_PAGAMENTO\nObrigado pela compra!" 15 50
  registrar_log "$NOME_OPERADOR" "Finalizou Venda" "Total: R\$ $TOTAL_VENDA | Pagamento: $METODOS_PAGAMENTO"

  # Salvar cupom de venda em /etc/pdv/cupons e /etc/pdv/cupons
  CUPOM_FILE="/etc/pdv/cupons/$NUM_CUPOM_cupom.txt"
  CUPOM_CUPONS="/etc/pdv/cupons/$NUM_CUPOM_cupom.txt"

  # Montar os itens para o cupom
  ITENS_CUPOM=""
  local index=1
  for item in "${ITENS_VENDA[@]}"; do
    ITENS_CUPOM+="$(printf "%-6s %-20s\n" "$index" "$item")"
    index=$((index + 1))
  done

  echo -e "======================= PDV =======================\nCUPOM: $NUM_CUPOM\nNúmero  Produto              Quantidade          Valor\n--------------------------------------------------------------------------\n$ITENS_CUPOM--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\nMétodo(s) de Pagamento:\n$METODOS_PAGAMENTO\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $HORARIO\n==================================================" > "$CUPOM_FILE"

  # Copiar o cupom para o diretório /etc/pdv/cupons
  cp "$CUPOM_FILE" "$CUPOM_CUPONS"

  # Salvar cupom no Redis
  redis-cli -h $DB_HOST HMSET "compra:$NUM_CUPOM" status "finalizada" operador "$OPERADOR" total "$TOTAL_VENDA" itens "$ITENS_CUPOM" pagamentos "$METODOS_PAGAMENTO"

  # Mostrar mensagem final
  dialog --msgbox "Cupom salvo em $CUPOM_FILE" 6 40
  registrar_log "$NOME_OPERADOR" "Cupom Salvo" "Cupom salvo em $CUPOM_FILE"

  # Resetar variáveis e voltar para a tela de vendas
  TOTAL_VENDA=0
  ITENS_VENDA=()
  MODO="produto"
  PAGAMENTOS=()
}

# Função para recuperar cupom cancelado
recuperar_cupom() {
  # Solicitar o número do cupom
  NUM_CUPOM=$(dialog --stdout --inputbox "Digite o número do cupom:" 8 40)
  NUM_CUPOM=$(echo "$NUM_CUPOM" | sed 's/[^0-9_]//g')

  # Tentar encontrar o cupom no Redis
  CUPOM_ENCONTRADO=$(redis-cli -h $DB_HOST EXISTS "compra:$NUM_CUPOM")
  if [ "$CUPOM_ENCONTRADO" -eq 1 ]; then
    ITENS=$(redis-cli -h $DB_HOST HGET "compra:$NUM_CUPOM" itens | sed 's/\\n/\n/g')
    TOTAL=$(redis-cli -h $DB_HOST HGET "compra:$NUM_CUPOM" total)

    # Carregar os itens na venda atual sem reindexá-los
    IFS=$'\n' read -rd '' -a ITENS_VENDA <<<"$ITENS"
    TOTAL_VENDA="$TOTAL"

    dialog --msgbox "Cupom recuperado com sucesso!" 6 40
    registrar_log "$NOME_OPERADOR" "Recuperar Cupom" "Cupom $NUM_CUPOM recuperado."
    return
  fi

  # Caso não encontre no Redis, verificar no diretório de cupons
  if [ -f "/etc/pdv/cupons/${NUM_CUPOM}_compra_cancelada.txt" ]; then
    ITENS_CUPOM=$(grep -A 100 "Produto" "/etc/pdv/cupons/${NUM_CUPOM}_compra_cancelada.txt" | sed '1d')

    # Carregar os itens na venda atual sem reindexá-los
    IFS=$'\n' read -rd '' -a ITENS_VENDA <<<"$ITENS_CUPOM"
    
    # Atualizar o subtotal com base nos itens recuperados
    recalcular_subtotal

    dialog --msgbox "Cupom recuperado com sucesso!" 6 40
    registrar_log "$NOME_OPERADOR" "Recuperar Cupom" "Cupom $NUM_CUPOM recuperado do arquivo."
  else
    dialog --msgbox "Nenhum cupom encontrado." 6 40
  fi
}

# Verificar se os diretórios de vendas e cupons existem, se não, criar
[ ! -d "/etc/pdv/cupons" ] && mkdir -p "/etc/pdv/cupons"

# Iniciar o log
echo "Log iniciado em $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"

# Executar o fluxo completo
autenticar_operador
capturar_input_produto
