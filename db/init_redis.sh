#!/bin/sh

# Inicializar o Redis com o arquivo de configuração que habilita a persistência
redis-server /usr/local/etc/redis/redis.conf --daemonize yes

# Verificar se o Redis está pronto
until redis-cli ping | grep -q "PONG"; do
  echo "Esperando Redis estar pronto..."
  sleep 1
done

echo "Redis está pronto. Criando usuário admin..."

# Criar o usuário admin no Redis
redis-cli HMSET "usuario:admin" nome "admin" senha "admin" role "admin"
if [ $? -eq 0 ]; then
  echo "Usuário admin criado com sucesso."
else
  echo "Erro ao criar o usuário admin."
  exit 1
fi

# Salvar os dados
redis-cli save
if [ $? -eq 0 ]; then
  echo "Dados salvos com sucesso."
else
  echo "Erro ao salvar os dados no Redis."
  exit 1
fi

# Manter o container rodando
tail -f /dev/null
