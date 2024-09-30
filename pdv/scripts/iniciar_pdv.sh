#!/bin/bash

# Caminho para salvar cupons
CUPOM_DIR="/etc/pdv/cupons"
mkdir -p "$CUPOM_DIR"

# Log de venda
LOG_FILE="/var/log/funcoes/vendas.log"
mkdir -p /var/log/funcoes

# Variáveis iniciais
TOTAL_VENDA=0
ITEMS=""
ID_VENDA=$(date '+%Y%m%d%H%M%S')
OPERADOR=""
FORM_PAGAMENTO=""

# Função para exibir o menu de opções ao pressionar ESC
exibir_menu_opcoes() {
    opcao=$(dialog --stdout --menu "Opções" 10 40 3 \
        1 "Finalizar compra" \
        2 "Cancelar compra" \
        3 "Continuar compra")

    case $opcao in
        1) finalizar_venda ;;
        2) cancelar_compra ;;
        3) adicionar_produto ;;
    esac
}

# Função para adicionar produtos
adicionar_produto() {
    while true; do
        # Solicitar código do produto
        CODIGO=$(dialog --stdout --inputbox "Digite o código do produto ou pressione ESC para opções:" 10 50)

        # Verifica se o usuário pressionou ESC
        if [ $? -ne 0 ]; then
            exibir_menu_opcoes
            continue
        fi

        # Verificar se o produto existe no Redis
        NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
        PRECO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
        ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

        if [ -z "$NOME" ]; then
            dialog --msgbox "Produto não encontrado!" 6 40
            continue
        fi

        # Solicitar quantidade do produto
        QUANTIDADE=$(dialog --stdout --inputbox "Digite a quantidade para o produto $NOME:" 10 50)

        # Verificar se há estoque
        if [ "$ESTOQUE" -le 0 ]; then
            dialog --msgbox "Estoque insuficiente!" 6 40
            continue
        fi

        # Verificar se a quantidade solicitada não excede o estoque
        NOVO_ESTOQUE=$((ESTOQUE - QUANTIDADE))
        if [ "$NOVO_ESTOQUE" -lt 0 ]; then
            dialog --msgbox "Quantidade solicitada excede o estoque disponível!" 6 40
            continue
        fi

        # Atualizar estoque no Redis
        redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" estoque "$NOVO_ESTOQUE"

        # Calcular total e atualizar a venda
        ITEM_TOTAL=$(echo "$PRECO * $QUANTIDADE" | bc)
        TOTAL_VENDA=$(echo "$TOTAL_VENDA + $ITEM_TOTAL" | bc)
        ITEMS="$ITEMS\nProduto: $NOME | Quantidade: $QUANTIDADE | Valor: R$ $ITEM_TOTAL"

        # Exibir tela de atualização da venda
        dialog --title "PDV - Venda em andamento" --msgbox "Produto adicionado: $NOME\nQuantidade: $QUANTIDADE\nSubtotal: R$ $TOTAL_VENDA" 10 50
    done
}

# Função para cancelar compra
cancelar_compra() {
    dialog --msgbox "Compra cancelada." 6 40
    exit 0
}

# Função para finalizar venda
finalizar_venda() {
    # Perguntar a forma de pagamento
    FORM_PAGAMENTO=$(dialog --stdout --menu "Forma de Pagamento" 10 50 3 \
        1 "Dinheiro" \
        2 "Cartão" \
        3 "Pix")

    # Registrar no log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Operador: $OPERADOR] Venda finalizada. Total: R$ $TOTAL_VENDA. Forma de pagamento: $FORM_PAGAMENTO" >> "$LOG_FILE"

    # Gerar cupom
    CUPOM_FILE="$CUPOM_DIR/cupom_$ID_VENDA.txt"
    echo "================= CUPOM =================" > "$CUPOM_FILE"
    echo -e "$ITEMS" >> "$CUPOM_FILE"
    echo "------------------------------------------" >> "$CUPOM_FILE"
    echo "Total: R$ $TOTAL_VENDA" >> "$CUPOM_FILE"
    echo "Forma de pagamento: $FORM_PAGAMENTO" >> "$CUPOM_FILE"
    echo "Operador: $OPERADOR" >> "$CUPOM_FILE"
    echo "Horário: $(date '+%d-%m-%Y %H:%M:%S')" >> "$CUPOM_FILE"
    echo "==========================================" >> "$CUPOM_FILE"

    # Exibir mensagem de conclusão e gerar cupom
    dialog --title "Cupom gerado" --msgbox "Venda finalizada com sucesso!\nCupom gerado em: $CUPOM_FILE" 10 50
    exit 0
}

# Função para iniciar a venda
iniciar_venda() {
    # Perguntar o código do operador
    OPERADOR=$(dialog --stdout --inputbox "Digite o código do operador:" 10 50)

    # Exibir a tela de PDV e rodar o loop de vendas
    adicionar_produto
}

# Iniciar o PDV
iniciar_venda
