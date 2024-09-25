#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

# Função para criar setor
criar_setor() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Solicita o nome do setor
  NOME_SETOR=$(dialog --stdout --inputbox "Nome do Setor (ex: FRIOS, HORTIFRUTI):" 0 0)
  [ $? -ne 0 ] && return

  # Verifica se o setor já existe
  SETOR_EXISTENTE=$(redis-cli -h $DB_HOST EXISTS "setor:$NOME_SETOR")
  if [ "$SETOR_EXISTENTE" -eq 1 ]; then
    dialog --msgbox "Setor já cadastrado!" 6 40
    return 1
  fi

  # Salva o setor no banco de dados
  redis-cli -h $DB_HOST SADD "setores" "$NOME_SETOR"

  # Registrar log da ação de criação de setor
  registrar_log "admin" "Criou setor" "Nome do Setor: $NOME_SETOR"

  # Exibe mensagem de sucesso
  dialog --msgbox "Setor $NOME_SETOR criado com sucesso!" 6 40
}
