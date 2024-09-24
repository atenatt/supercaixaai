FROM redis:alpine

# Comando para inicializar o Redis e criar o usuário admin
RUN redis-server --daemonize yes && \
    redis-cli HMSET "usuario:admin" nome "admin" senha "admin" role "admin" && \
    redis-cli save && \
    redis-cli shutdown && \
    echo "Usuário admin criado com sucesso (usuário: admin, senha: admin)."
