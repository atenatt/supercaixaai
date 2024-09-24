FROM redis:alpine

# Copiar o script init_redis.sh para dentro do container
COPY init_redis.sh /usr/local/bin/init_redis.sh

# Tornar o script executável
RUN chmod +x /usr/local/bin/init_redis.sh

# Comando para iniciar o Redis e garantir a criação do usuário admin na execução
ENTRYPOINT ["/usr/local/bin/init_redis.sh"]
