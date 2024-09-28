# Guia de Instalação - SuperCaixa AI (Docker Edition)

Este guia descreve como configurar o ambiente de desenvolvimento do **SuperCaixa AI** localmente, utilizando **Docker** em vez de Vagrant. O objetivo é provisionar automaticamente todos os containers necessários para o servidor, os PDVs e o banco de dados.

## Pré-requisitos

Antes de iniciar a instalação, certifique-se de que seu ambiente tenha as seguintes dependências instaladas:

1. **Git** - Para clonar o repositório e gerenciar versões.
   - [Guia de Instalação](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
   
2. **Docker** - Para criar e gerenciar containers.
   - [Guia de Instalação](https://docs.docker.com/get-docker/)
   
3. **Docker Compose** - Para definir e rodar os serviços Docker.
   - [Guia de Instalação](https://docs.docker.com/compose/install/)
   
4. **VSCode** - Editor de texto recomendado para desenvolvimento.
   - [Guia de Instalação](https://code.visualstudio.com/)

## Passo a Passo de Instalação

### 1. Clone o Repositório

Comece clonando o repositório do **SuperCaixa AI** em seu ambiente local:

```bash
git clone https://github.com/supercaixaai/supercaixaai.git
cd supercaixaai
```

### 2. Configuração do Ambiente com Docker

O **SuperCaixa AI** utiliza **Docker** para provisionar o servidor, os PDVs e o banco de dados Redis. Para configurar o ambiente:

1. Certifique-se de que o **Docker** e o **Docker Compose** estão instalados corretamente.
2. Execute o comando abaixo para iniciar os containers (servidor web, PDVs e banco de dados Redis):

   ```bash
   docker-compose up -d
   ```

Isso criará quatro containers:
- **web_server**: O servidor web que roda o Nginx.
- **pdv1**: Primeiro PDV (interface com Dialog).
- **pdv2**: Segundo PDV (interface com Dialog).
- **redis_db**: Banco de dados Redis utilizado para armazenar informações de usuários, mercadorias e promoções.

### 3. Acessar os Containers

Após subir os containers, você pode acessar cada um deles utilizando o comando `docker exec`. Aqui estão alguns exemplos:

- **Acessar o PDV 1**:
  ```bash
  docker exec -it pdv1 sh
  ```

- **Acessar o PDV 2**:
  ```bash
  docker exec -it pdv2 sh
  ```

- **Acessar o banco de dados Redis**:
  ```bash
  docker exec -it redis_db redis-cli
  ```

### 4. Inicializar o Sistema PDV

Após acessar o container do PDV (pdv1 ou pdv2), inicie o sistema executando:

```bash
pdv
```

Isso abrirá a interface do **SuperCaixa AI** com todas as funcionalidades do PDV, como abrir caixa, consultar mercadorias e acessar o painel administrativo.

### 5. Configurações Adicionais

- **Configuração de Backup**: O sistema possui scripts automáticos de backup que salvam os dados do Redis em um diretório compartilhado `/backup` entre os containers.
- **Promoções**: O sistema possui um monitoramento contínuo de promoções, que ajusta automaticamente os preços ao término das promoções definidas.

### 6. Parar ou Remover os Containers

Se precisar parar ou remover os containers, utilize os comandos abaixo:

- **Parar os containers** (mantendo o estado):
  ```bash
  docker-compose stop
  ```

- **Remover completamente os containers** (dados serão mantidos no volume compartilhado):
  ```bash
  docker-compose down
  ```
