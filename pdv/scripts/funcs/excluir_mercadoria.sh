#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

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
