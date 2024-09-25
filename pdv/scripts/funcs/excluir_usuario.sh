#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

# Função para excluir qualquer usuário, exceto o admin
excluir_usuario() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  USUARIO=$(dialog --stdout --inputbox "Nome do usuário a ser excluído:" 0 0)
  [ $? -ne 0 ] && return

  # Verificar se o usuário é o admin
  if [ "$USUARIO" = "admin" ]; then
    dialog --msgbox "O usuário 'admin' não pode ser excluído!" 6 40
    # Registrar log de tentativa de exclusão do usuário admin
    registrar_log "admin" "Tentou excluir o usuário 'admin'" "Operação não permitida"
    return 1
  fi

  # Verificar se o usuário existe no Redis
  ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$USUARIO" role)
  if [ -z "$ROLE" ]; then
    dialog --msgbox "Usuário não encontrado!" 6 40
    # Registrar log de tentativa de exclusão de usuário não encontrado
    registrar_log "admin" "Tentou excluir usuário" "Usuário não encontrado: $USUARIO"
    return 1
  fi

  # Confirmar exclusão
  dialog --yesno "Deseja realmente excluir o usuário $USUARIO?" 7 40
  if [ $? -eq 0 ]; then
    # Excluir usuário do Redis
    redis-cli -h $DB_HOST DEL "usuario:$USUARIO"
    dialog --msgbox "Usuário $USUARIO excluído com sucesso!" 6 40

    # Registrar log da exclusão de usuário
    registrar_log "admin" "Excluiu usuário" "Usuário: $USUARIO, Função: $ROLE"
  else
    dialog --msgbox "Exclusão cancelada." 6 40
    # Registrar log de cancelamento de exclusão
    registrar_log "admin" "Cancelou exclusão de usuário" "Usuário: $USUARIO"
  fi
}
