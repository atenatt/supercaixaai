#!/bin/bash
# Atualizando pacotes e instalando Docker, Go e Python nos PDVs
apk update
apk add python3 py3-pip dialog redis

# Criar link simbólico de python para python3
ln -s /usr/bin/python3 /usr/bin/python

# Adicionando a chave ssh do host na maquina
cat /shared/ssh_key/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys

# Tornar o script da interface executável
chmod +x /shared/scripts/pdv_interface.sh

# Adicionar alias para facilitar o uso
echo "alias pdv='/shared/scripts/pdv_interface.sh'" >> /home/vagrant/.profile