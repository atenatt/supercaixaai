#!/bin/sh

# Função para consultar mercadorias por setor
consultar_por_setor() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Coletar os setores disponíveis
  SETORES=$(redis-cli -h $DB_HOST SMEMBERS "setores")

  if [ -z "$SETORES" ]; then
    dialog --msgbox "Nenhum setor cadastrado." 6 50
    return 1
  fi

  # Montar a lista de setores para o dialog
  OPCOES_SETORES=""
  for SETOR in $SETORES; do
    OPCOES_SETORES="$OPCOES_SETORES $SETOR $SETOR"
  done

  # Selecionar o setor
  SETOR=$(dialog --stdout --menu "Selecione o setor para listar itens:" 15 50 6 $OPCOES_SETORES)
  [ $? -ne 0 ] && return

  # Buscar mercadorias do setor no Redis
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")
  LISTAGEM=""

  for MERCADORIA in $MERCADORIAS; do
    SETOR_MERCADORIA=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" setor)
    if [ "$SETOR_MERCADORIA" = "$SETOR" ]; then
      NOME=$(redis-cli -h $DB_HOST HGET "$MERCADORIA" nome)
      LISTAGEM="$LISTAGEM\n$NOME"
    fi
  done

  if [ -z "$LISTAGEM" ]; then
    dialog --msgbox "Nenhuma mercadoria encontrada no setor $SETOR." 6 40
  else
    dialog --msgbox "Mercadorias do setor $SETOR:\n$LISTAGEM" 15 50
  fi
}
