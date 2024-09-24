#!/bin/sh

# Variável global para saber se o administrador está autenticado
ADMIN_AUTENTICADO=0

# Carregar todas as funções a partir de /etc/pdv/funcs/
echo "Carregando funções automaticamente..."
for func_script in /etc/pdv/funcs/*.sh; do
  if [ -f "$func_script" ]; then
    echo "Carregando $func_script..."
    source "$func_script" || { echo "Erro ao carregar $func_script"; exit 1; }
  fi
done

echo "Todas as funções foram carregadas com sucesso."

# Função para o menu de administração (somente para administradores)
menu_administracao() {
  if [ "$ADMIN_AUTENTICADO" -eq 0 ]; then
    autenticar_usuario "admin" || return 1
    ADMIN_AUTENTICADO=1
  fi

  while true; do
    OPCAO_ADMIN=$(dialog --stdout --menu "Administração - SuperCaixa AI" 15 50 7 \
      1 "Cadastrar Usuário" \
      2 "Cadastrar Mercadoria" \
      3 "Excluir Mercadoria" \
      4 "Consultar Todas Mercadorias" \
      5 "Consultar Todos Usuários" \
      6 "Excluir Operador" \
      7 "Voltar")

    [ $? -ne 0 ] && break

    case $OPCAO_ADMIN in
      1) cadastrar_usuario ;;
      2) cadastrar_mercadoria ;;
      3) excluir_mercadoria ;;
      4) consultar_todas_mercadorias ;;
      5) consultar_todos_usuarios ;;
      6) excluir_operador ;;
      7) break ;;
    esac
  done
}

# Função para o menu principal com controle de acesso baseado em roles
menu_principal() {
  while true; do
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 15 50 6 \
      1 "Administração" \
      2 "Abrir Caixa (Operador e Fiscal)" \
      3 "Consultar Mercadoria (Fiscal e Admin)" \
      4 "Sair")

    [ $? -ne 0 ] && break

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
