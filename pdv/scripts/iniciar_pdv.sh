#!/bin/sh

# Carregar funções do PDV
source /etc/pdv/funcs/funcs_venda.sh
source /etc/pdv/funcs/funcs_logs.sh 

# Função principal para iniciar o PDV
iniciar_pdv() {
  while true; do
    # Menu principal do PDV
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 20 50 10 \
      1 "Abrir Caixa" \
      2 "Registrar Venda" \
      3 "Consultar Mercadoria" \
      4 "Fechar Caixa" \
      5 "Sair")

    [ $? -ne 0 ] && clear && exit 0

    case $OPCAO in
      1) iniciar_pdv ;;       # Função de abrir o caixa
      2) registrar_venda ;;   # Função de registrar vendas
      3) consultar_mercadoria ;; # Função para consultar mercadorias
      4) fechar_caixa ;;      # Função de fechar o caixa
      5) clear && exit 0 ;;   # Sair do sistema
    esac
  done
}

# Inicializar o PDV
iniciar_pdv
