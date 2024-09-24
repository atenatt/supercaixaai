#!/bin/sh

# Função para consultar todos os usuários cadastrados com paginação
consultar_todos_usuarios() {
  # Verifica se o administrador já está autenticado
  if [ "$ADMIN_AUTENTICADO" -ne 1 ]; then
    autenticar_usuario "admin" || return 1
  fi

  # Pega todas as chaves de usuários cadastrados
  USUARIOS=$(redis-cli -h $DB_HOST KEYS "usuario:*")

  if [ -z "$USUARIOS" ]; then
    dialog --msgbox "Nenhum usuário cadastrado." 6 40
    return 1
  fi

  # Número de itens por página
  ITENS_POR_PAGINA=5
  TOTAL_USUARIOS=$(echo "$USUARIOS" | wc -l)
  PAGINAS=$((($TOTAL_USUARIOS + $ITENS_POR_PAGINA - 1) / $ITENS_POR_PAGINA))

  PAGINA_ATUAL=1

  while true; do
    # Calcular o intervalo de itens a serem mostrados
    INICIO=$(($ITENS_POR_PAGINA * ($PAGINA_ATUAL - 1)))
    FIM=$(($INICIO + $ITENS_POR_PAGINA))

    # Inicializar a variável LISTAGEM para a página atual
    LISTAGEM=""

    # Loop através dos usuários para exibir os dados
    for USUARIO in $(echo "$USUARIOS" | tail -n +$(($INICIO + 1)) | head -n $ITENS_POR_PAGINA); do
      NOME=$(echo "$USUARIO" | cut -d: -f2)
      ROLE=$(redis-cli -h $DB_HOST HGET "usuario:$NOME" role)

      # Adicionar os detalhes do usuário na LISTAGEM
      if [ -n "$NOME" ] && [ -n "$ROLE" ]; then
        LISTAGEM="$LISTAGEM\nUsuário: $NOME | Role: $ROLE"
      fi
    done

    # Verificar se a listagem está vazia
    if [ -z "$LISTAGEM" ]; then
      dialog --msgbox "Nenhum usuário cadastrado na página $PAGINA_ATUAL." 6 40
    else
      # Mostrar a página de usuários
      dialog --msgbox "Usuários (Página $PAGINA_ATUAL de $PAGINAS): $LISTAGEM" 15 70
    fi

    # Se houver mais páginas, perguntar ao usuário se quer continuar
    if [ $PAGINA_ATUAL -lt $PAGINAS ]; then
      dialog --yesno "Ver próxima página?" 7 40
      if [ $? -ne 0 ]; then
        break
      fi
      PAGINA_ATUAL=$(($PAGINA_ATUAL + 1))
    else
      break
    fi
  done
}
