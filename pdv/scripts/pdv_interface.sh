#!/bin/sh

# Carregar o arquivo de funções
source /etc/pdv/funcoes.sh

# Loop principal do menu
while true; do
  OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 15 50 5 \
    1 "Cadastrar Mercadoria" \
    2 "Cadastrar Usuário" \
    3 "Abrir Caixa" \
    4 "Consultar Mercadoria" \
    5 "Excluir Mercadoria" \
    6 "Sair")
  
  # Verifica se o usuário cancelou ou saiu do menu
  [ $? -ne 0 ] && break

  case $OPCAO in
    1) cadastrar_mercadoria ;;
    2) cadastrar_usuario ;;
    3) abrir_caixa ;;
    4) consultar_mercadoria ;;
    5) excluir_mercadoria ;;
    6) break ;;
  esac
done

clear
