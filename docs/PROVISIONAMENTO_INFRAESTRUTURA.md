# Provisionamento da Infraestrutura do SuperCaixa AI 🖥️🛠️

Este documento descreve o processo de provisionamento da infraestrutura do **SuperCaixa AI**, que inclui um servidor principal e dois PDVs (Pontos de Venda). Agora, utilizando **Docker** em vez de Vagrant, temos uma infraestrutura mais leve, portátil e fácil de escalar.

## Requisitos 📋

Certifique-se de que o ambiente atenda aos seguintes requisitos antes de iniciar o provisionamento:
- **Docker** instalado
- **Docker Compose** instalado
- **Git** instalado

## Passo a Passo para o Provisionamento 🚀

### 1. Clone o Repositório do Projeto

Primeiro, faça o clone do repositório **SuperCaixa AI** para o seu ambiente local:

```bash
git clone https://github.com/supercaixaai/supercaixaai.git
cd supercaixaai
```

### 2. Configure o Ambiente com Docker Compose

A infraestrutura é definida no arquivo `docker-compose.yml`. Ele define três serviços principais:
- **web**: Servidor web principal que executa o Nginx.
- **pdv1**: Primeiro ponto de venda (PDV 1).
- **pdv2**: Segundo ponto de venda (PDV 2).
- **redis_db**: O banco de dados Redis que armazena informações de mercadorias, promoções e usuários.

Para provisionar todos os containers de uma só vez, execute:

```bash
docker-compose up -d
```

### 3. Verificar o Status dos Containers 🖥️

Após executar o `docker-compose`, você pode verificar o status dos containers e garantir que estão rodando corretamente com:

```bash
docker ps
```

Isso exibirá os containers em execução:
- **web_server**: Servidor Nginx
- **pdv1**: Primeiro PDV
- **pdv2**: Segundo PDV
- **redis_db**: Banco de dados Redis

### 4. Acessar os Containers 🔧

Você pode se conectar diretamente a qualquer container via **docker exec**:

- Acessar o **PDV 1**:
  ```bash
  docker exec -it pdv1 sh
  ```

- Acessar o **PDV 2**:
  ```bash
  docker exec -it pdv2 sh
  ```

- Acessar o **Redis** (banco de dados):
  ```bash
  docker exec -it redis_db redis-cli
  ```

### 5. Provisionamento de Serviços e Funções 🌟

Dentro dos containers **PDV 1** e **PDV 2**, você terá acesso aos scripts que controlam o fluxo de operações de caixa, cadastro de mercadorias, promoções, e muito mais. A interface principal é gerida pelo script `pdv_interface.sh`, que contém todas as opções para o usuário final, como:

- Abrir caixa
- Cadastrar mercadorias
- Consultar mercadorias e promoções
- Cadastrar e gerenciar usuários

### 6. Gerenciamento de Promoções 🔔

As promoções são monitoradas automaticamente por um processo que é iniciado junto com o container PDV. Esse processo verifica as promoções expiradas a cada hora e restaura os preços originais automaticamente.

Se você quiser criar ou consultar promoções, poderá fazer isso diretamente pelo menu de administração no PDV.

### 7. Backup do Banco de Dados 💾

Uma função de backup está configurada para realizar backups automáticos do banco Redis. Você pode realizar backups manuais através da interface ou consultar o último backup realizado.

- Para realizar o backup:
  ```bash
  docker exec -it pdv1 sh /etc/pdv/funcs/backup_banco.sh
  ```

### 8. Parar ou Destruir os Containers 🛑

Quando quiser parar ou remover os containers:

- Para parar os containers sem destruí-los:
  ```bash
  docker-compose down
  ```

- Para destruir completamente os containers e volumes:
  ```bash
  docker-compose down --volumes
  ```

Isso removerá os containers, mas o volume de backup dos dados do Redis será mantido, garantindo que você não perca dados cruciais.

---

Agora o **SuperCaixa AI** está provisionado e pronto para ser utilizado! 🎉

