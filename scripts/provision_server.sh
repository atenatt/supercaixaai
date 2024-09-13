#!/bin/bash
# Atualizando pacotes e instalando Docker e Go no servidor
apt-get update

# Instalação do pacote Ansible
apt-get install -y ansible

# Instalação do Nginx
apt-get install -y nginx

# Iniciando e habilitando o Nginx
systemctl start nginx
systemctl enable nginx

# Adicionando os hosts no diretório /etc/hosts
sudo bash -c "cat <<EOT >> /etc/hosts
172.16.0.1 srv-sc01
172.16.0.2 db-sc01
172.16.0.11 pdv-sc01
172.16.0.12 pdv-sc02
EOT"

# Removendo a chave ssh antiga
sudo rm -rf /shared/ssh_key/id_rsa*

# Gerando a nova chave ssh
ssh-keygen -t rsa -b 4096 -f /shared/ssh_key/id_rsa -N ""

# Copiando a chave ssh gerada para o /home/vagrant/.ssh/id_rsa
cp /shared/ssh_key/id_rsa /home/vagrant/.ssh/

# Adicionando os hosts no arquivo /etc/ansible/hosts
sudo bash -c "cat <<EOT > /etc/ansible/hosts
[pdvs]
pdv-sc01
pdv-sc02
[dbs]
db-sc01
EOT"