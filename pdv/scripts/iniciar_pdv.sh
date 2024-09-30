#!/bin/sh

# Carregar todas as funções a partir de /etc/pdv/funcs/
echo "Carregando funções automaticamente..."
for func_script in /etc/pdv/funcs/*.sh; do
  if [ -f "$func_script" ]; then
    # Verifica se o script é o monitorar_promocoes.sh e o ignora
    if [ "$(basename "$func_script")" = "monitorar_promocoes.sh" ]; then
      echo "Ignorando $func_script..."
      continue
    fi

    echo "Carregando $func_script..."
    source "$func_script" || { echo "Erro ao carregar $func_script"; exit 1; }
  fi
done

echo "Todas as funções foram carregadas com sucesso."

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
      1) abrir_caixa ;;       # Função de abrir o caixa
      2) registrar_venda ;;   # Função de registrar vendas
      3) consultar_mercadoria ;; # Função para consultar mercadorias
      4) fechar_caixa ;;      # Função de fechar o caixa
      5) clear && exit 0 ;;   # Sair do sistema
    esac
  done
}

# Inicializar o PDV
iniciar_pdv
