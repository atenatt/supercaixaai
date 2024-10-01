#!/bin/bash

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Definir variáveis globais
TOTAL_VENDA=0
ITENS_VENDA=""
OPERADOR=""
HORARIO=$(date '+%d/%m %H:%M:%S')
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
  clear
  local mensagem="$1"

  # Definir o número total de linhas reservadas para os itens
  NUM_LINHAS_ITENS=20

  # Calcular o número de itens já adicionados
  NUM_ITENS=$(echo -e "$ITENS_VENDA" | grep -c '^')

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
  INPUTBOX_CONTENT+="$ITENS_VENDA$LINHAS_VAZIAS"
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
      mensagem="Digite o código do produto ou pressione ESC para finalizar:"
      desenhar_interface "$mensagem"
      retorno=$?
      INPUT="$dialog_output"

      # Se o operador pressionar ESC, finalizar a compra
      if [ $retorno -ne 0 ]; then
        finalizar_compra
        break
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

      # Se o operador pressionar ESC, finalizar a compra
      if [ $retorno -ne 0 ]; then
        finalizar_compra
        break
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

      # Adicionar o item à lista de venda
      ITENS_VENDA+="$(printf "%-20s %-20s R\$ %-10s\n" "$NOME_PRODUTO" "$QUANTIDADE" "$SUBTOTAL_ITEM")"

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

# Função para finalizar a compra
finalizar_compra() {
  clear
  dialog --msgbox "Total da compra: R\$ $TOTAL_VENDA\nObrigado pela compra!" 10 40
  registrar_log "$NOME_OPERADOR" "Finalizou Venda" "Total: R\$ $TOTAL_VENDA"

  # Salvar cupom de venda em /etc/pdv/vendas
  CUPOM_FILE="/etc/pdv/vendas/$(date '+%Y%m%d%H%M%S')_cupom.txt"
  echo -e "======================= PDV =======================\nProduto              Quantidade              Valor\n--------------------------------------------------------------------------\n$ITENS_VENDA--------------------------------------------------------------------------\nSubtotal: R\$ $TOTAL_VENDA\n==================================================\nOperador: $NOME_OPERADOR                               Horário: $HORARIO\n==================================================" > "$CUPOM_FILE"

  # Mostrar mensagem final
  dialog --msgbox "Cupom salvo em $CUPOM_FILE" 6 40
  registrar_log "$NOME_OPERADOR" "Cupom Salvo" "Cupom salvo em $CUPOM_FILE"
  exit 0
}

# Verificar se o diretório de vendas existe, se não, criar
[ ! -d "/etc/pdv/vendas" ] && mkdir -p "/etc/pdv/vendas"

# Iniciar o log
echo "Log iniciado em $(date '+%Y-%m-%d %H:%M:%S')" > "$LOG_FILE"

# Executar o fluxo completo
autenticar_operador
capturar_input_produto
