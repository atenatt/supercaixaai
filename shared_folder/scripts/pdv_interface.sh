#!/bin/sh

# Configurações
DB_HOST="172.16.0.2"

# Função para cadastrar mercadoria
cadastrar_mercadoria() {
  NOME=$(dialog --stdout --inputbox "Nome da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_CUSTO=$(dialog --stdout --inputbox "Preço de Custo:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_VENDA=$(dialog --stdout --inputbox "Preço de Venda:" 0 0)
  [ $? -ne 0 ] && return

  # Salvar no Redis
  redis-cli -h $DB_HOST HMSET "mercadoria:$NOME" nome "$NOME" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA"

  dialog --msgbox "Mercadoria cadastrada com sucesso!" 6 40
}

# Função para consultar mercadoria
consultar_mercadoria() {
  NOME=$(dialog --stdout --inputbox "Nome da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  # Recuperar do Redis
  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$NOME")

  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    dialog --msgbox "Dados da Mercadoria:\n$RESULTADO" 10 50
  fi
}

# Loop principal
while true; do
  OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 0 0 0 \
    1 "Cadastrar Mercadoria" \
    2 "Consultar Mercadoria" \
    3 "Sair")
  
  [ $? -ne 0 ] && break

  case $OPCAO in
    1) cadastrar_mercadoria ;;
    2) consultar_mercadoria ;;
    3) break ;;
  esac
done

clear
