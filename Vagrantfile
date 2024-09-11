Vagrant.configure("2") do |config|

  # Configuração do servidor na rede host-only existente
  config.vm.define "srv-sc01" do |server|
    server.vm.box = "ubuntu/bionic64"
    
    # Configuração de rede com IP fixo na rede existente 192.168.56.x
    server.vm.network "private_network", ip: "192.168.56.101"

    # Sincronização de pastas
    server.vm.synced_folder ".", "/vagrant"

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
    pdv_name = "pdv-sc-00#{i}"
    pdv_ip = "192.168.56.10#{i}"

    config.vm.define pdv_name do |pdv|
      pdv.vm.box = "generic/alpine313"
      
      # Configuração de rede com IP fixo na rede existente 192.168.56.x
      pdv.vm.network "private_network", ip: pdv_ip

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
