# Dockerfile para o servidor do SuperCaixa AI
FROM golang:1.19-alpine

# Definir o diretório de trabalho dentro do container
WORKDIR /app

# Copiar os arquivos de código para dentro do container
COPY . .

# Instalar as dependências
#RUN go mod download

# Compilar o aplicativo
#RUN go build -o /supercaixaai

# Expor a porta do serviço (ajuste conforme necessário)
EXPOSE 8080

# Comando para rodar a aplicação
CMD ["/app/supercaixaai"]
