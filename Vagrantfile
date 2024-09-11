Vagrant.configure("2") do |config|

  # Caminho do diretório compartilhado no host
  shared_folder_path = "./shared_folder"

  # Configuração do servidor na rede host-only existente
  config.vm.define "srv-sc01" do |server|
    server.vm.box = "ubuntu/bionic64"
    
    # Configuração de rede com IP fixo na nova rede 172.16.0.x
    server.vm.network "private_network", ip: "172.16.0.1"

    # Ajusta o hostname para o nome da máquina
    server.vm.hostname = "srv-sc01"

    # Sincronização de pastas
    server.vm.synced_folder ".", "/vagrant"
    
    # Diretório compartilhado entre servidor e PDVs
    server.vm.synced_folder shared_folder_path, "/shared"

    # Provisão com script externo
    server.vm.provision "shell", path: "scripts/provision_server.sh"

    # Configuração de recursos do servidor
    server.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end

  # Configuração dos PDVs na rede host-only existente
  (1..2).each do |i|
    pdv_name = "pdv-sc0#{i}"
    pdv_ip = "172.16.0.1#{i}"

    config.vm.define pdv_name do |pdv|
      pdv.vm.box = "generic/alpine313"
      
      # Configuração de rede com IP fixo na nova rede 172.16.0.x
      pdv.vm.network "private_network", ip: pdv_ip

      # Ajusta o hostname para o nome da máquina
      pdv.vm.hostname = pdv_name

      # Diretório compartilhado entre servidor e PDVs
      pdv.vm.synced_folder shared_folder_path, "/shared"

      # Provisão com script externo
      pdv.vm.provision "shell", path: "scripts/provision_pdv.sh"

      # Configuração de recursos dos PDVs
      pdv.vm.provider "virtualbox" do |vb|
        vb.memory = "512"
        vb.cpus = 1
      end
    end
  end
end
