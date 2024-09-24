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
    OPCAO_ADMIN=$(dialog --stdout --menu "Administração - SuperCaixa AI" 25 50 8 \
      1 "Cadastrar Usuário" \
      2 "Cadastrar Mercadoria" \
      3 "Excluir Mercadoria" \
      4 "Consultar Todas Mercadorias" \
      5 "Consultar Todos Usuários" \
      6 "Excluir Usuário" \
      7 "Criar Setor" \
      8 "Consultar Mercadorias por Setor" \
      9 "Voltar")

    [ $? -ne 0 ] && break

    case $OPCAO_ADMIN in
      1) cadastrar_usuario ;;
      2) cadastrar_mercadoria ;;
      3) excluir_mercadoria ;;
      4) consultar_todas_mercadorias ;;
      5) consultar_todos_usuarios ;;
      6) excluir_usuario ;;
      7) criar_setor ;;
      8) consultar_por_setor ;;
      9) break ;;
    esac
  done
}

# Função para o menu principal com controle de acesso baseado em roles
menu_principal() {
  while true; do
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 25 50 9 \
      1 "Abrir Caixa" \
      2 "Consultar Mercadoria" \
      3 "Futuramente" \
      4 "Futuramente" \
      5 "Futuramente" \
      6 "Futuramente" \
      7 "Futuramente" \
      8 "Administração" \
      9 "Sair")

    [ $? -ne 0 ] && break

    case $OPCAO in
      1) abrir_caixa ;;
      2) consultar_mercadoria ;;
      8) menu_administracao ;;
      9) break ;;
    esac
  done
}

# Inicializar o sistema
menu_principal
