FROM redis:alpine

# Copiar o arquivo de configuração redis.conf para dentro do container
COPY redis.conf /usr/local/etc/redis/redis.conf

# Copiar o script init_redis.sh para dentro do container
COPY init_redis.sh /usr/local/bin/init_redis.sh

# Tornar o script executável
RUN chmod +x /usr/local/bin/init_redis.sh

# Comando para iniciar o Redis com o arquivo de configuração e garantir a criação do usuário admin
ENTRYPOINT ["/usr/local/bin/init_redis.sh"]
