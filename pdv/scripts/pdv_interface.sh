#!/bin/sh

# Variável global para saber se o administrador está autenticado
ADMIN_AUTENTICADO=0

# Carregar todas as funções a partir de /etc/pdv/funcs/
echo "Carregando funções..."

source /etc/pdv/funcs/autenticar_usuario.sh || { echo "Erro ao carregar autenticar_usuario.sh"; exit 1; }
source /etc/pdv/funcs/cadastrar_mercadoria.sh || { echo "Erro ao carregar cadastrar_mercadoria.sh"; exit 1; }
source /etc/pdv/funcs/cadastrar_usuario.sh || { echo "Erro ao carregar cadastrar_usuario.sh"; exit 1; }
source /etc/pdv/funcs/abrir_caixa.sh || { echo "Erro ao carregar abrir_caixa.sh"; exit 1; }
source /etc/pdv/funcs/consultar_mercadoria.sh || { echo "Erro ao carregar consultar_mercadoria.sh"; exit 1; }
source /etc/pdv/funcs/excluir_mercadoria.sh || { echo "Erro ao carregar excluir_mercadoria.sh"; exit 1; }

echo "Todas as funções foram carregadas com sucesso."

# Função para o menu de administração (somente para administradores)
menu_administracao() {
  if [ "$ADMIN_AUTENTICADO" -eq 0 ]; then
    autenticar_usuario "admin" || return 1
    ADMIN_AUTENTICADO=1
  fi

  while true; do
    OPCAO_ADMIN=$(dialog --stdout --menu "Administração - SuperCaixa AI" 15 50 4 \
      1 "Cadastrar Usuário" \
      2 "Cadastrar Mercadoria" \
      3 "Excluir Mercadoria" \
      4 "Voltar")

    [ $? -ne 0 ] && break

    case $OPCAO_ADMIN in
      1) cadastrar_usuario ;;
      2) cadastrar_mercadoria ;;
      3) excluir_mercadoria ;;
      4) break ;;
    esac
  done
}

# Menu principal com controle de acesso baseado em roles
menu_principal() {
  while true; do
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 15 50 6 \
      1 "Administração" \
      2 "Abrir Caixa (Operador e Fiscal)" \
      3 "Consultar Mercadoria (Fiscal e Admin)" \
      4 "Sair")

    [ $? -ne 0 ] && clear && break

    case $OPCAO in
      1) menu_administracao ;;
      2) abrir_caixa ;;
      3) consultar_mercadoria ;;
      4) break ;;
    esac
  done
}

# Inicializar o sistema (usuário admin é criado via Dockerfile)
menu_principal
