# Provisionamento da Infraestrutura do SuperCaixa AI

Este documento descreve o processo passo a passo para provisionar a infraestrutura do **SuperCaixa AI**, que inclui o servidor e dois PDVs (Pontos de Venda), utilizando Vagrant.

## Requisitos
Antes de iniciar o provisionamento, certifique-se de que você tem os seguintes itens configurados no seu ambiente:
- **Vagrant** instalado
- **VirtualBox** instalado
- **Git** instalado

## Passo a Passo para o Provisionamento

### 1. Clone o Repositório do Projeto

Clone o repositório do projeto para o seu ambiente local:

```bash
git clone https://github.com/supercaixaai/supercaixaai.git
cd supercaixaai
```

### 2. Inicie o Provisionamento

Para provisionar o servidor e os dois PDVs, execute o comando abaixo na raiz do projeto:

```bash
vagrant up
```

Isso criará e provisionará três máquinas virtuais:
- **srv-sc01**: Servidor principal.
- **pdv-sc-001**: Primeiro PDV.
- **pdv-sc-002**: Segundo PDV.

### 3. Acessar as Máquinas Virtuais

Você pode acessar cada uma das máquinas utilizando o SSH:

- Para acessar o **servidor**:
  ```bash
  vagrant ssh srv-sc01
  ```

- Para acessar o **PDV 1**:
  ```bash
  vagrant ssh pdv-sc-001
  ```

- Para acessar o **PDV 2**:
  ```bash
  vagrant ssh pdv-sc-002
  ```

### 4. Atualizar o Sistema nas Máquinas

Se necessário, você pode atualizar os pacotes de software dentro de cada máquina virtual. Use os comandos a seguir, dependendo da máquina:

- No **servidor**:
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

- Nos **PDVs**:
  ```bash
  sudo apk update && sudo apk upgrade
  ```

### 5. Parar ou Destruir as Máquinas Virtuais

Quando você terminar de usar as máquinas virtuais, você pode pará-las ou destruí-las:

- Para parar as máquinas (mantendo o estado):
  ```bash
  vagrant halt
  ```

- Para destruir as máquinas (exclui as VMs completamente):
  ```bash
  vagrant destroy
  ```