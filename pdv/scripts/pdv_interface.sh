#!/bin/bash

# Variável global para saber se o administrador está autenticado
ADMIN_AUTENTICADO=0

source /etc/pdv/inciar_pdv.sh

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

  # Verificação se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -eq 0 ]; then
    echo "Solicitando autenticação de administrador..."  # Debug

    # Chama a função de autenticação e verifica o retorno
    autenticar_usuario "admin"
    if [ $? -ne 0 ]; then
      echo "Falha na autenticação."  # Debug
      dialog --msgbox "Falha na autenticação!" 6 40
      return 1
    else
      ADMIN_AUTENTICADO=1
      echo "Administrador autenticado com sucesso!"  # Debug
    fi
  fi

  while true; do
    echo "Exibindo menu de administração..."  # Debug
    OPCAO_ADMIN=$(dialog --stdout --menu "Administração - SuperCaixa AI" 25 50 12 \
      1 "Cadastrar Usuário" \
      2 "Cadastrar Mercadoria" \
      3 "Consultar Mercadorias por Setor" \
      4 "Consultar Promoção" \
      5 "Consultar Todas Mercadorias" \
      6 "Consultar Todos Usuários" \
      7 "Consultar Logs" \
      8 "Criar Promoção" \
      9 "Criar Setor" \
      10 "Editar Mercadoria" \
      11 "Excluir Mercadoria" \
      12 "Excluir Usuário" \
      13 "Realizar Backup do Banco de Dados" \
      14 "Verificar Último Backup" \
      15 "Voltar")

    [ $? -ne 0 ] && break

    case $OPCAO_ADMIN in
      1) cadastrar_usuario ;;
      2) cadastrar_mercadoria ;;
      3) consultar_por_setor ;;
      4) consultar_promocao ;;
      5) consultar_todas_mercadorias ;;
      6) consultar_todos_usuarios ;;
      7) consultar_logs ;;
      8) criar_promocao ;;
      9) criar_setor ;;
      10) editar_mercadoria ;;
      11) excluir_mercadoria ;;
      12) excluir_usuario ;;
      13) backup_banco ;;
      14) verificar_ultimo_backup ;;
      15) echo "Saindo do menu de administração..." && break ;;
    esac
  done
}

# Função para o menu principal com controle de acesso baseado em roles
menu_principal() {
  while true; do
    OPCAO=$(dialog --stdout --menu "SuperCaixa AI - PDV" 25 50 9 \
      1 "Iniciar PDV" \
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
      1) iniciar_pdv ;;
      2) consultar_mercadoria ;;
      8) menu_administracao ;;  # Acesso ao menu de administração
      9) clear && break ;;
    esac
  done
}

# Inicializar o sistema
menu_principal
