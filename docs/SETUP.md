# Guia de Instalação - SuperCaixa AI

Este guia descreve como configurar o ambiente de desenvolvimento do **SuperCaixa AI** localmente, utilizando **Vagrant** para provisionar as máquinas virtuais e outras ferramentas essenciais. Siga os passos abaixo para garantir que o sistema esteja corretamente configurado.

## Pré-requisitos

Antes de iniciar a instalação, certifique-se de que seu ambiente tenha as seguintes dependências instaladas:

1. **Git** - Para clonar o repositório e gerenciar versões.
   - [Guia de Instalação](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
   
2. **Vagrant** - Para provisionamento das máquinas virtuais.
   - [Guia de Instalação](https://www.vagrantup.com/docs/installation)
   
3. **VirtualBox** - Para executar as máquinas virtuais criadas pelo Vagrant.
   - [Guia de Instalação](https://www.virtualbox.org/wiki/Downloads)

4. **VSCode** - Editor de texto recomendado para desenvolvimento.
   - [Guia de Instalação](https://code.visualstudio.com/)

## Passo a Passo de Instalação

### 1. Clone o Repositório

Comece clonando o repositório do **SuperCaixa AI** em seu ambiente local:

```bash
git clone https://github.com/supercaixaai/supercaixaai.git
cd supercaixaai
```

### 2. Configuração do Ambiente com Vagrant

O **SuperCaixa AI** utiliza **Vagrant** para provisionar o servidor e os PDVs (Pontos de Venda) em máquinas virtuais. Para configurar o ambiente:

1. Certifique-se de que o **VirtualBox** está instalado.
2. Execute o comando abaixo para iniciar o provisionamento das máquinas virtuais (servidor e dois PDVs):

   ```bash
   vagrant up
   ```

Isso criará três máquinas virtuais:
- **srv-sc01**: Servidor principal (Ubuntu).
- **pdv-sc-001**: Primeiro PDV (Alpine Linux).
- **pdv-sc-002**: Segundo PDV (Alpine Linux).

### 3. Acessar as Máquinas Virtuais

Após o provisionamento, você pode acessar as máquinas via SSH:

- **Acessar o servidor**:
  ```bash
  vagrant ssh srv-sc01
  ```

- **Acessar o PDV 1**:
  ```bash
  vagrant ssh pdv-sc-001
  ```

- **Acessar o PDV 2**:
  ```bash
  vagrant ssh pdv-sc-002
  ```

### 4. Atualizar as Máquinas Virtuais

Durante o provisionamento, o sistema operacional de cada máquina é atualizado. Se precisar atualizar manualmente, siga os comandos abaixo:

- **No servidor (Ubuntu)**:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

- **Nos PDVs (Alpine Linux)**:
  ```bash
  sudo apk update && sudo apk upgrade
  ```

### 5. Parar ou Destruir as Máquinas Virtuais

Se precisar parar ou destruir as máquinas virtuais, utilize os comandos abaixo:

- **Parar as máquinas** (mantendo o estado):
  ```bash
  vagrant halt
  ```

- **Destruir as máquinas** (remover completamente):
  ```bash
  vagrant destroy
  ```