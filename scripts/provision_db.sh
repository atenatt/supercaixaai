#!/bin/bash
# Atualizando pacotes e instalando Docker, Go e Python nos PDVs
apk update
apk add python3 py3-pip

# Criar link simbólico de python para python3
ln -s /usr/bin/python3 /usr/bin/python

# Adicionando a chave ssh do host na maquina
cat /shared/ssh_key/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys