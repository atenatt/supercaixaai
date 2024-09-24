#!/bin/sh

# Função para consultar todas as mercadorias cadastradas
consultar_todas_mercadorias() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Consultar todas as mercadorias no Redis
  MERCADORIAS=$(redis-cli -h $DB_HOST KEYS "mercadoria:*")

  if [ -z "$MERCADORIAS" ]; then
    dialog --msgbox "Nenhuma mercadoria cadastrada." 6 40
  else
    dialog --msgbox "Mercadorias cadastradas:\n$MERCADORIAS" 15 60
  fi
}
