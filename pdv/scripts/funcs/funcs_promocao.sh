#!/bin/sh

source /etc/pdv/funcs/funcs_logs.sh

# Função para criar uma promoção
criar_promocao() {
  log_funcs "Iniciando criação de promoção."

  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Solicitar o código do produto
  CODIGO=$(dialog --stdout --inputbox "Digite o código GTIN ou Interno do produto para promoção:" 0 0)
  [ $? -ne 0 ] && log_funcs "Criação de promoção cancelada pelo usuário." && return

  # Verificar se o produto existe
  PRODUTO_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "mercadoria:$CODIGO")
  if [ "$PRODUTO_EXISTENTE" -eq 0 ]; then
    dialog --msgbox "Produto não encontrado!" 6 40
    log_funcs "Produto não encontrado para o código $CODIGO."
    return 1
  fi

  # Buscar e exibir as informações do produto
  NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
  PRECO_ATUAL=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" preco_venda)
  ESTOQUE=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" estoque)
  dialog --msgbox "Informações do Produto:\n\nNome: $NOME\nPreço Atual: $PRECO_ATUAL\nEstoque: $ESTOQUE" 10 40
  log_funcs "Produto $NOME com código $CODIGO encontrado. Preço atual: $PRECO_ATUAL."

  # Solicitar confirmação para prosseguir com a criação da promoção
  dialog --yesno "Deseja prosseguir para criar uma promoção para este produto?" 7 40
  [ $? -ne 0 ] && log_funcs "Criação de promoção cancelada após exibição de informações do produto." && return

  # Solicitar o preço promocional
  PRECO_PROMOCAO=$(dialog --stdout --inputbox "Digite o preço promocional (deve ser menor que o preço atual):" 0 0)
  [ $? -ne 0 ] && log_funcs "Criação de promoção cancelada na entrada do preço promocional." && return

  # Verificar se o preço promocional é menor que o preço atual
  if [ $(echo "$PRECO_PROMOCAO >= $PRECO_ATUAL" | bc) -eq 1 ]; then
    dialog --msgbox "Erro: O preço promocional deve ser menor que o preço atual!" 6 40
    log_funcs "Erro ao criar promoção: preço promocional ($PRECO_PROMOCAO) é maior ou igual ao preço atual ($PRECO_ATUAL)."
    return 1
  fi

  # Solicitar a data final da promoção usando um calendário
  DATA_FINAL_PROMOCAO=$(dialog --stdout --calendar "Selecione a data final da promoção:" 0 0)
  [ $? -ne 0 ] && log_funcs "Criação de promoção cancelada na seleção de data." && return

  # Converter a data final para formato UNIX timestamp
  DATA_FINAL_UNIX=$(date -d "$DATA_FINAL_PROMOCAO" +%s)

  # Guardar o preço original e a promoção
  redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" preco_original "$PRECO_ATUAL"
  redis-cli -h $DB_HOST HSET "mercadoria:$CODIGO" preco_venda "$PRECO_PROMOCAO"
  redis-cli -h $DB_HOST HSET "promocao:$CODIGO" expira_em "$DATA_FINAL_UNIX" preco_promocional "$PRECO_PROMOCAO"

  dialog --msgbox "Promoção criada com sucesso para o produto $NOME! Preço Promocional: $PRECO_PROMOCAO" 6 40
  log_funcs "Promoção criada com sucesso para o produto $NOME com preço promocional de $PRECO_PROMOCAO até $DATA_FINAL_PROMOCAO."

}

# Função para consultar promoção de um produto
consultar_promocao() {
  log_funcs "Consultando promoção para um produto."

  CODIGO=$(dialog --stdout --inputbox "Digite o código GTIN ou Interno do produto:" 0 0)
  [ $? -ne 0 ] && log_funcs "Consulta de promoção cancelada pelo usuário." && return

  # Verificar se o produto tem uma promoção ativa
  PROMOCAO_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "promocao:$CODIGO")
  if [ "$PROMOCAO_EXISTENTE" -eq 0 ]; then
    dialog --msgbox "Nenhuma promoção ativa para este produto!" 6 40
    log_funcs "Nenhuma promoção ativa encontrada para o produto com código $CODIGO."
    return 1
  fi

  # Buscar informações da promoção
  NOME=$(redis-cli -h $DB_HOST HGET "mercadoria:$CODIGO" nome)
  PRECO_PROMOCAO=$(redis-cli -h $DB_HOST HGET "promocao:$CODIGO" preco_promocional)
  DATA_EXPIRACAO=$(redis-cli -h $DB_HOST HGET "promocao:$CODIGO" expira_em)
  DATA_EXPIRACAO_FORMATADA=$(date -d @$DATA_EXPIRACAO)

  dialog --msgbox "Promoção ativa para o produto $NOME\n\nPreço Promocional: $PRECO_PROMOCAO\nExpira em: $DATA_EXPIRACAO_FORMATADA" 10 40
  log_funcs "Promoção ativa consultada para o produto $NOME com preço promocional $PRECO_PROMOCAO até $DATA_EXPIRACAO_FORMATADA."
}
