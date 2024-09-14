#!/bin/bash
# Atualizando pacotes e instalando Docker e Go no servidor
apt-get update

# Instalação do Nginx
apt-get install -y nginx

# Instalando Go
wget https://golang.org/dl/go1.17.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile

# Iniciando e habilitando o Nginx
systemctl start nginx
systemctl enable nginx

# Removendo a chave ssh antiga
sudo rm -rf /shared/ssh_key/id_rsa*

# Gerando a nova chave ssh
ssh-keygen -t rsa -b 4096 -f /shared/ssh_key/id_rsa -N ""

# Copiando a chave ssh gerada para o /home/vagrant/.ssh/
cp /shared/ssh_key/id_rsa /home/vagrant/.ssh/

# Adicionando os hosts no arquivo /etc/ansible/hosts
sudo bash -c "cat <<EOT > /etc/ansible/hosts
[pdvs]
pdv-sc01
pdv-sc02
[dbs]
db-sc01
EOT"

# Copiando os arquivos index.html e style.css para o diretório do Nginx
cp /shared/web/* /var/www/html/

# Instalação do Ansible
apt-get install -y ansible

# Executar o playbook do Ansible para instalar e configurar Redis
ansible-playbook /shared/scripts/ansible/install_redis.yml -i /shared/scripts/ansible/hosts.ini