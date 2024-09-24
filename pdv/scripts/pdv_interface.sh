#!/bin/sh

# Verificar se estamos no diretório correto e carregar as funções
echo "Carregando funções..."

source /etc/pdv/funcs/autenticar_usuario.sh || { echo "Erro ao carregar autenticar_usuario.sh"; exit 1; }
source /etc/pdv/funcs/cadastrar_mercadoria.sh || { echo "Erro ao carregar cadastrar_mercadoria.sh"; exit 1; }
source /etc/pdv/funcs/cadastrar_usuario.sh || { echo "Erro ao carregar cadastrar_usuario.sh"; exit 1; }
source /etc/pdv/funcs/abrir_caixa.sh || { echo "Erro ao carregar abrir_caixa.sh"; exit 1; }
source /etc/pdv/funcs/consultar_mercadoria.sh || { echo "Erro ao carregar consultar_mercadoria.sh"; exit 1; }
source /etc/pdv/funcs/excluir_mercadoria.sh || { echo "Erro ao carregar excluir_mercadoria.sh"; exit 1; }

echo "Todas as funções foram carregadas com sucesso."

# Menu principal com controle de acesso baseado em roles
menu_principal() {
  while true; do
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 15 50 6 \
      1 "Cadastrar Usuário (Admin)" \
      2 "Cadastrar Mercadoria (Admin)" \
      3 "Abrir Caixa (Operador e Fiscal)" \
      4 "Consultar Mercadoria (Fiscal e Admin)" \
      5 "Excluir Mercadoria (Admin)" \
      6 "Sair")

    [ $? -ne 0 ] && clear && break

    case $OPCAO in
      1) cadastrar_usuario ;;
      2) cadastrar_mercadoria ;;
      3) abrir_caixa ;;
      4) consultar_mercadoria ;;
      5) excluir_mercadoria ;;
      6) clear && break ;;
    esac
  done
}

# Inicializar o sistema (usuário admin é criado via Dockerfile)
menu_principal
