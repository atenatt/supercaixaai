#!/bin/sh

# Função para verificar o último backup realizado no container Redis
verificar_ultimo_backup() {
  echo "Verificando o último backup no container Redis..."  # Debug

  # Listar os backups e pegar o mais recente
  ULTIMO_BACKUP=$(ls -t /data/redis* | head -n 1)

  # Verificar se foi encontrado um backup
  if [ -z "$ULTIMO_BACKUP" ]; then
    dialog --msgbox "Nenhum backup encontrado." 6 40
  else
    echo "Último backup encontrado: $ULTIMO_BACKUP"  # Debug
    dialog --msgbox "Último backup realizado: $ULTIMO_BACKUP" 6 40
  fi
}
