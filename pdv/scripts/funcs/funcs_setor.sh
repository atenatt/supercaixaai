#!/bin/sh

source /etc/pdv/funcs/funcs_logs.sh

# Função para criar setor
criar_setor() {
  log_funcs "Iniciando criação de setor."

  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  log_funcs "Usuário autenticado com sucesso para criação de setor."

  # Solicita o nome do setor
  NOME_SETOR=$(dialog --stdout --inputbox "Nome do Setor (ex: FRIOS, HORTIFRUTI):" 0 0)
  [ $? -ne 0 ] && log_funcs "Criação de setor cancelada pelo usuário." && return

  # Verifica se o setor já existe
  SETOR_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "setor:$NOME_SETOR")
  if [ "$SETOR_EXISTENTE" -eq 1 ]; then
    dialog --msgbox "Setor já cadastrado!" 6 40
    log_funcs "Tentativa de criação falhou: Setor já cadastrado - Nome: $NOME_SETOR."
    return 1
  fi

  # Salva o setor no banco de dados
  redis-cli -h $DB_HOST SADD "setores" "$NOME_SETOR"
  
  # Registrar log da ação de criação de setor
  log_funcs "Criou setor: Nome do Setor: $NOME_SETOR"

  # Exibe mensagem de sucesso
  dialog --msgbox "Setor $NOME_SETOR criado com sucesso!" 6 40
}

# Função para consultar mercadorias por setor
consultar_por_setor() {
  log_funcs "Iniciando consulta de mercadorias por setor."

  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  log_funcs "Usuário autenticado com sucesso para consulta de mercadorias por setor."

  # Coletar os setores disponíveis
  SETORES=$(redis-cli -h $DB_HOST SMEMBERS "setores")

  if [ -z "$SETORES" ]; then
    dialog --msgbox "Nenhum setor cadastrado." 6 50
    log_funcs "Nenhum setor cadastrado encontrado."
    return 1
  fi

  # Montar a lista de setores para o dialog
  OPCOES_SETORES=""
  for SETOR in $SETORES; do
    OPCOES_SETORES="$OPCOES_SETORES $SETOR $SETOR"
  done

  # Selecionar o setor
  SETOR=$(dialog --stdout --menu "Selecione o setor para listar itens:" 15 50 6 $OPCOES_SETORES)
  [ $? -ne 0 ] && log_funcs "Consulta de mercadorias por setor cancelada pelo usuário." && return

  log_funcs "Setor selecionado para consulta: $SETOR."

  # Buscar mercadorias do setor no Redis
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")
  LISTAGEM=""

  for MERCADORIA in $MERCADORIAS; do
    SETOR_MERCADORIA=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" setor)
    if [ "$SETOR_MERCADORIA" = "$SETOR" ]; then
      NOME=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" nome)
      CODIGO=$(echo "$MERCADORIA" | cut -d':' -f2)
      PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" preco_venda)
      ESTOQUE=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" estoque)
      LISTAGEM="$LISTAGEM\nCódigo: $CODIGO | Nome: $NOME | Preço: R$ $PRECO_VENDA | Estoque: $ESTOQUE"
    fi
  done

  if [ -z "$LISTAGEM" ]; then
    dialog --msgbox "Nenhuma mercadoria encontrada no setor $SETOR." 6 40
    log_funcs "Nenhuma mercadoria encontrada no setor $SETOR."
  else
    dialog --msgbox "Mercadorias do setor $SETOR:\n$LISTAGEM" 20 60
    log_funcs "Mercadorias do setor $SETOR consultadas com sucesso."
  fi
}
