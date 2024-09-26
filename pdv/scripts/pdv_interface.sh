#!/bin/sh

# Variável global para saber se o administrador está autenticado
ADMIN_AUTENTICADO=0

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


# Função para o menu de administração (somente para administradores)
menu_administracao() {
  echo "Entrando no menu de administração..."  # Debug

  if [ "$ADMIN_AUTENTICADO" -eq 0 ]; then
    autenticar_usuario "admin" || { 
      echo "Falha na autenticação";  # Debug
      return 1
    }
    ADMIN_AUTENTICADO=1
    echo "Administrador autenticado com sucesso!"  # Debug
  fi

  while true; do
    OPCAO_ADMIN=$(dialog --stdout --menu "Administração - SuperCaixa AI" 25 50 12 \
      1 "Cadastrar Usuário" \
      2 "Cadastrar Mercadoria" \
      3 "Excluir Mercadoria" \
      4 "Consultar Todas Mercadorias" \
      5 "Consultar Todos Usuários" \
      6 "Excluir Usuário" \
      7 "Criar Setor" \
      8 "Consultar Mercadorias por Setor" \
      9 "Editar Mercadoria" \
      10 "Consultar Logs" \
      11 "Realizar Backup do Banco de Dados" \
      12 "Verificar Último Backup" \
      13 "Criar Promoção" \
      14 "Consultar Promoção" \
      15 "Voltar")

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
      9) editar_mercadoria ;;
      10) consultar_logs ;;
      11) backup_banco ;;
      12) verificar_ultimo_backup ;;
      13) criar_promocao ;;
      14) consultar_promocao ;;
      15) echo "Saindo do menu de administração..." && break ;;
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

    [ $? -ne 0 ] && clear && break

    case $OPCAO in
      1) abrir_caixa ;;
      2) consultar_mercadoria ;;
      8) menu_administracao ;;  # Acesso ao menu de administração
      9) clear && break ;;
    esac
  done
}

# Inicializar o sistema
menu_principal
