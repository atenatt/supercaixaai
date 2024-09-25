#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

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
