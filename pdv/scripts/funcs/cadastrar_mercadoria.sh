#!/bin/sh

# Função para cadastrar mercadoria com todas as informações em uma única tela
cadastrar_mercadoria() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Coleta todos os dados necessários para o cadastro da mercadoria em uma única tela
  DADOS=$(dialog --stdout --form "Cadastro de Mercadoria" 15 60 6 \
    "Nome:" 1 1 "" 1 20 30 0 \
    "Código GTIN:" 2 1 "" 2 20 30 0 \
    "Código Interno:" 3 1 "" 3 20 30 0 \
    "Preço de Custo:" 4 1 "" 4 20 30 0 \
    "Preço de Venda:" 5 1 "" 5 20 30 0 \
    "Estoque:" 6 1 "" 6 20 30 0)

  # Se o usuário cancelar o formulário
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
  redis-cli -h $DB_HOST HMSET "mercadoria:$GTIN" nome "$NOME" codigo_interno "$CODIGO_INTERNO" preco_custo "$PRECO_CUSTO" preco_venda "$PRECO_VENDA" estoque "$ESTOQUE"

  # Exibir mensagem de sucesso
  dialog --msgbox "Mercadoria cadastrada com sucesso!" 6 40
}
