#!/bin/bash
# Atualizando pacotes e instalando Docker e Go no servidor
apt update

# Instalação do Nginx
apt install -y nginx wget curl openssh-server

# Instalando Go
wget https://golang.org/dl/go1.17.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile

# Iniciando e habilitando o Nginx
service nginx start
service ssh start