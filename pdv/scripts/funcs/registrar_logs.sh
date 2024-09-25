#!/bin/sh

# Função para registrar logs de ações de usuários
registrar_log() {
  USUARIO=$1
  ACAO=$2
  DETALHES=$3
  DATA_HORA=$(date "+%Y-%m-%d %H:%M:%S")
  DATA=$(date "+%Y-%m-%d")

  # Escreve a ação no arquivo de log
  echo "[$DATA_HORA] $USUARIO: $ACAO - $DETALHES" >> /var/log/supercaixaai_$DATA.log
}
