#!/bin/sh

# Carregar a função de log
source /etc/pdv/funcs/registrar_logs.sh

# Função para abrir o caixa (Operador e Fiscal)
abrir_caixa() {
  # Autentica o operador e captura o nome do usuário autenticado
  autenticar_usuario "operador" || return 1
  USUARIO_ATUAL=$USUARIO

  OPERADOR=$(dialog --stdout --inputbox "Nome do Operador:" 0 0)
  [ $? -ne 0 ] && return

  # Registrar abertura do caixa no Redis
  redis-cli -h $DB_HOST SET "caixa:$OPERADOR" "aberto"
  dialog --msgbox "Caixa aberto para o operador $OPERADOR." 6 40

  # Registrar log da ação de abertura de caixa
  registrar_log "$USUARIO_ATUAL" "Abriu o caixa" "Operador: $OPERADOR"
}
