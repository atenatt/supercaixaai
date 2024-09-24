#!/bin/sh

# Função para cadastrar mercadoria
cadastrar_mercadoria() {
  GTIN=$(dialog --stdout --inputbox "GTIN da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  CODIGO_INTERNO=$(dialog --stdout --inputbox "Código Interno da Mercadoria (opcional):" 0 0)
  [ $? -ne 0 ] && return

  NOME=$(dialog --stdout --inputbox "Nome da Mercadoria:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_CUSTO=$(dialog --stdout --inputbox "Preço de Custo:" 0 0)
  [ $? -ne 0 ] && return

  PRECO_VENDA=$(dialog --stdout --inputbox "Preço de Venda:" 0 0)
  [ $? -ne 0 ] && return

  # Salvar no Redis usando o código GTIN como chave
  redis-cli -h $DB_HOST HMSET "mercadoria:$GTIN" gtin "$GTIN" codigo_interno "$CODIGO_INTERNO" nome "$NOME" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA"

  # Se um código interno foi fornecido, salvá-lo também
  if [ ! -z "$CODIGO_INTERNO" ]; then
    redis-cli -h $DB_HOST HMSET "mercadoria:$CODIGO_INTERNO" gtin "$GTIN" codigo_interno "$CODIGO_INTERNO" nome "$NOME" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA"
  fi

  dialog --msgbox "Mercadoria cadastrada com sucesso!" 6 40
}

# Função para cadastrar usuário
cadastrar_usuario() {
  USUARIO=$(dialog --stdout --inputbox "Nome do Usuário:" 0 0)
  [ $? -ne 0 ] && return

  SENHA=$(dialog --stdout --passwordbox "Senha do Usuário:" 0 0)
  [ $? -ne 0 ] && return

  # Salvar no Redis
  redis-cli -h $DB_HOST HMSET "usuario:$USUARIO" nome "$USUARIO" senha "$SENHA"

  dialog --msgbox "Usuário cadastrado com sucesso!" 6 40
}

# Função para abrir caixa
abrir_caixa() {
  OPERADOR=$(dialog --stdout --inputbox "Nome do Operador:" 0 0)
  [ $? -ne 0 ] && return

  # Definir o caixa como aberto no Redis
  redis-cli -h $DB_HOST SET "caixa:$OPERADOR" "aberto"

  dialog --msgbox "Caixa aberto para o operador $OPERADOR." 6 40
}

# Função para consultar mercadoria pelo código GTIN ou código interno
consultar_mercadoria() {
  CODIGO=$(dialog --stdout --inputbox "Informe o Código GTIN ou Código Interno:" 0 0)
  [ $? -ne 0 ] && return

  # Recuperar a mercadoria do Redis usando o código informado (GTIN ou Código Interno)
  RESULTADO=$(redis-cli -h $DB_HOST HGETALL "mercadoria:$CODIGO")

  if [ -z "$RESULTADO" ]; then
    dialog --msgbox "Mercadoria não encontrada." 6 40
  else
    dialog --msgbox "Dados da Mercadoria:\n$RESULTADO" 10 50
  fi
}
