#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/funcs_logs.sh

# Função para cadastrar mercadoria com todas as informações em uma única tela
cadastrar_mercadoria() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Coletar os setores disponíveis
  SETORES=$(redis-cli -h $DB_HOST SMEMBERS "setores")

  if [ -z "$SETORES" ]; then
    dialog --msgbox "Nenhum setor cadastrado. Crie um setor antes de cadastrar uma mercadoria." 6 50
    return 1
  fi

  # Montar a lista de setores para o dialog
  OPCOES_SETORES=""
  for SETOR in $SETORES; do
    OPCOES_SETORES="$OPCOES_SETORES $SETOR $SETOR"
  done

  # Coleta os dados necessários para o cadastro da mercadoria
  DADOS=$(dialog --stdout --form "Cadastro de Mercadoria" 18 50 0 \
    "Nome:" 1 1 "" 1 20 30 0 \
    "Código GTIN:" 2 1 "" 2 20 30 0 \
    "Código Interno:" 3 1 "" 3 20 30 0 \
    "Preço de Custo:" 4 1 "" 4 20 30 0 \
    "Preço de Venda:" 5 1 "" 5 20 30 0 \
    "Estoque:" 6 1 "" 6 20 30 0)

  [ $? -ne 0 ] && return

  # Selecionar o setor
  SETOR=$(dialog --stdout --menu "Selecione o setor:" 15 50 6 $OPCOES_SETORES)
  [ $? -ne 0 ] && return

  # Separar os dados preenchidos
  NOME=$(echo "$DADOS" | sed -n 1p)
  GTIN=$(echo "$DADOS" | sed -n 2p)
  CODIGO_INTERNO=$(echo "$DADOS" | sed -n 3p)
  PRECO_CUSTO=$(echo "$DADOS" | sed -n 4p)
  PRECO_VENDA=$(echo "$DADOS" | sed -n 5p)
  ESTOQUE=$(echo "$DADOS" | sed -n 6p)

  # Verificar se os campos obrigatórios foram preenchidos
  if [ -z "$NOME" ] || [ -z "$GTIN" ] || [ -z "$CODIGO_INTERNO" ] || [ -z "$PRECO_VENDA" ]; then
    dialog --msgbox "Todos os campos obrigatórios (Nome, Código GTIN, Código Interno, Preço de Venda) devem ser preenchidos." 8 40
    return 1
  fi

  # Salvar os dados no Redis
  redis-cli -h $DB_HOST HMSET "mercadoria:$GTIN" nome "$NOME" codigo_interno "$CODIGO_INTERNO" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA" estoque "$ESTOQUE" setor "$SETOR"

  # Registrar log da ação de cadastro de mercadoria
  registrar_log "admin" "Cadastrou mercadoria" "Nome: $NOME, GTIN: $GTIN, Código Interno: $CODIGO_INTERNO, Preço: $PRECO_VENDA, Estoque: $ESTOQUE, Setor: $SETOR"

  # Exibir mensagem de sucesso
  dialog --msgbox "Mercadoria cadastrada com sucesso no setor $SETOR!" 6 40
}

# Função para consultar mercadoria (Fiscal e Admin)
consultar_mercadoria() {
  # Verifica se o usuário é fiscal ou administrador
  autenticar_usuario "fiscal" || autenticar_usuario "admin" || return 1

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno:" 0 0)
  [ $? -ne 0 ] && return

  # Buscar dados da mercadoria no Redis
  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$CODIGO")

  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
    PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
    ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)
    SETOR=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" setor)
    dialog --msgbox "Nome: $NOME\nPreço de Venda: R$ $PRECO_VENDA\nEstoque: $ESTOQUE\nSetor: $SETOR" 10 50
  fi
}

# Função para consultar todas as mercadorias cadastradas com paginação
consultar_todas_mercadorias() {
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Pega todas as chaves de mercadorias cadastradas
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")

  if [ -z "$MERCADORIAS" ]; then
    dialog --msgbox "Nenhuma mercadoria cadastrada." 6 40
    return 1
  fi

  ITENS_POR_PAGINA=5
  TOTAL_MERCADORIAS=$(echo "$MERCADORIAS" | wc -l)
  PAGINAS=$((($TOTAL_MERCADORIAS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))

  PAGINA_ATUAL=1

  while true; do
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))

    LISTAGEM=""

    for MERCADORIA in $(echo "$MERCADORIAS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      CODIGO=$(echo "$MERCADORIA" | cut -d: -f2)
      NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
      PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
      ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

      if [ -n "$NOME" ] && [ -n "$PRECO_VENDA" ] && [ -n "$ESTOQUE" ]; then
        LISTAGEM="$LISTAGEM\nCódigo: $CODIGO | Nome: $NOME | Preço: R$ $PRECO_VENDA | Estoque: $ESTOQUE"
      fi
    done

    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhuma mercadoria encontrada na página $PAGINA_ATUAL." 6 40
    else
      dialog --msgbox "Mercadorias (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
    fi

    if [ $PAGINA_ATUAL -lt $PAGINAS ]; then
      dialog --yesno "Ver próxima página?" 7 40
      if [ $? -ne 0 ]; then
        break
      fi
      PAGINA_ATUAL=$(($PAGINA_ATUAL + 1))
    else
      break
    fi
  done
}

# Função para editar uma mercadoria existente
editar_mercadoria() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Solicita o código GTIN ou Interno da mercadoria a ser editada
  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno da mercadoria a ser editada:" 0 0)
  [ $? -ne 0 ] && return

  # Buscar dados da mercadoria no Redis
  MERCADORIA_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "mercadoria:$CODIGO")
  if [ "$MERCADORIA_EXISTENTE" -eq 0 ]; then
    dialog --msgbox "Mercadoria não encontrada!" 6 40
    # Registrar log de tentativa de edição de mercadoria não encontrada
    registrar_log "admin" "Tentou editar mercadoria" "Mercadoria não encontrada: Código $CODIGO"
    return 1
  fi

  # Buscar os dados atuais da mercadoria
  NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
  PRECO_CUSTO=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_custo)
  PRECO_VENDA=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
  ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)

  # Exibir o formulário com os dados atuais preenchidos para edição
  DADOS_EDITADOS=$(dialog --stdout --form "Editar Mercadoria - Código: $CODIGO" 20 50 0 \
    "Nome:" 1 1 "$NOME" 1 18 40 0 \
    "Preço de Custo:" 2 1 "$PRECO_CUSTO" 2 18 40 0 \
    "Preço de Venda:" 3 1 "$PRECO_VENDA" 3 18 40 0 \
    "Estoque:" 4 1 "$ESTOQUE" 4 18 40 0)

  [ $? -ne 0 ] && return

  # Separar os dados editados
  NOVO_NOME=$(echo "$DADOS_EDITADOS" | sed -n 1p)
  NOVO_PRECO_CUSTO=$(echo "$DADOS_EDITADOS" | sed -n 2p)
  NOVO_PRECO_VENDA=$(echo "$DADOS_EDITADOS" | sed -n 3p)
  NOVO_ESTOQUE=$(echo "$DADOS_EDITADOS" | sed -n 4p)

  # Atualizar os dados da mercadoria no Redis
  redis-cli -h $DB_HOST HMSET "mercadoria:$CODIGO" nome "$NOVO_NOME" preco_custo "$NOVO_PRECO_CUSTO" preco_venda "$NOVO_PRECO_VENDA" estoque "$NOVO_ESTOQUE"

  # Registrar log da ação de edição de mercadoria
  registrar_log "admin" "Editou mercadoria" "Código: $CODIGO, Nome: $NOVO_NOME, Preço de Venda: $NOVO_PRECO_VENDA, Estoque: $NOVO_ESTOQUE"

  # Exibir mensagem de sucesso
  dialog --msgbox "Mercadoria $NOVO_NOME atualizada com sucesso!" 6 40
}

# Função para excluir mercadoria (Somente Admin)
excluir_mercadoria() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  CODIGO=$(dialog --stdout --inputbox "Código GTIN ou Interno a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  # Confirmação antes de excluir a mercadoria
  dialog --yesno "Deseja excluir a mercadoria $CODIGO?" 7 40
  [ $? -eq 0 ] || return

  # Verifica se a mercadoria existe antes de excluir
  MERCADORIA_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "mercadoria:$CODIGO")
  if [ "$MERCADORIA_EXISTENTE" -eq 0 ]; then
    dialog --msgbox "Mercadoria não encontrada!" 6 40
    # Registrar log de tentativa de exclusão de mercadoria não encontrada
    registrar_log "admin" "Tentou excluir mercadoria" "Mercadoria não encontrada: Código $CODIGO"
    return 1
  fi

  # Exclui a mercadoria do Redis
  redis-cli -h $DB_HOST DEL "mercadoria:$CODIGO"

  # Registrar log da ação de exclusão de mercadoria
  registrar_log "admin" "Excluiu mercadoria" "Código: $CODIGO"

  # Exibir mensagem de sucesso
  dialog --msgbox "Mercadoria excluída!" 6 40
}

