# Estrutura de Diretórios - SuperCaixa AI

Este documento descreve a estrutura de diretórios do projeto **SuperCaixa AI**. A organização dos arquivos segue princípios de modularidade e manutenibilidade, facilitando o desenvolvimento, teste e expansão do sistema.

## Estrutura de Diretórios Atual

```
/bin        # Binários e executáveis do sistema
/cmd        # Comandos principais da aplicação (ex.: PDV, servidor)
/config     # Arquivos de configuração da aplicação e ambientes
/deploy     # Scripts de deploy e provisionamento (ex.: Vagrant, Docker)
/docs       # Documentação do projeto (ex.: ARQUITETURA.md, SETUP.md)
/internal   # Pacotes internos, específicos da aplicação, não exportáveis
/pkg        # Pacotes reutilizáveis e exportáveis, usados por outros projetos
/scripts    # Scripts de automação e provisionamento
/test       # Testes automatizados (unitários, de integração, etc.)
/ui         # Código da interface de usuário (web, futuramente)
/vendor     # Dependências externas (gerenciadas pelo Go Modules)
```

## Descrição de Cada Diretório

### /bin
- **Descrição**: Contém os binários gerados a partir do código-fonte da aplicação. Aqui estarão os executáveis do servidor e dos PDVs, prontos para execução.
- **Exemplo de Conteúdo**: `supercaixa_server`, `supercaixa_pdv`.

### /cmd
- **Descrição**: Diretório para os principais comandos da aplicação. É onde ficam as implementações principais do servidor e dos PDVs.
- **Exemplo de Conteúdo**: `server/main.go`, `pdv/main.go`.

### /config
- **Descrição**: Armazena arquivos de configuração do sistema, como arquivos YAML, JSON ou outros formatos necessários para configurar o ambiente de desenvolvimento, produção ou testes.
- **Exemplo de Conteúdo**: `config.yaml`, `db_config.json`.

### /deploy
- **Descrição**: Contém todos os scripts de deploy, sejam eles para provisionar a infraestrutura, configurar o ambiente de produção ou automação de containerização.
- **Exemplo de Conteúdo**: `Vagrantfile`, `docker-compose.yml`.

### /docs
- **Descrição**: Diretório que armazena toda a documentação do projeto, incluindo a arquitetura, setup, justificativas de tecnologias e demais informações necessárias para manter o projeto bem documentado.
- **Exemplo de Conteúdo**: `ARQUITETURA.md`, `SETUP.md`, `TECH_CHOICES.md`.

### /internal
- **Descrição**: Contém pacotes internos da aplicação que não devem ser exportados para fora do projeto. Eles são específicos da lógica de negócio e são isolados para proteger a integridade do sistema.
- **Exemplo de Conteúdo**: `internal/supercaixa/vendas.go`.

### /pkg
- **Descrição**: Armazena pacotes que podem ser reutilizados dentro do projeto ou por outros projetos. Eles são projetados para serem exportáveis e possuem uma interface bem definida.
- **Exemplo de Conteúdo**: `pkg/logger`, `pkg/database`.

### /scripts
- **Descrição**: Diretório dedicado a scripts de automação e provisionamento. Pode conter scripts Shell, Ansible, ou qualquer outro tipo de automação necessária para o ambiente de desenvolvimento ou produção.
- **Exemplo de Conteúdo**: `provision_server.sh`, `provision_pdv.sh`.

### /test
- **Descrição**: Repositório de arquivos de teste. Pode conter testes unitários, de integração ou qualquer outro tipo de teste automatizado para garantir a qualidade do código.
- **Exemplo de Conteúdo**: `test/vendas_test.go`.

### /ui
- **Descrição**: Diretório que conterá o código da interface de usuário do **SuperCaixa AI**. Atualmente, está reservado para desenvolvimento futuro da interface web ou de aplicativos móveis.
- **Exemplo de Conteúdo**: `ui/dashboard.html`, `ui/css/estilos.css`.

### /vendor
- **Descrição**: Diretório que contém as dependências externas gerenciadas pelo Go Modules, garantindo que o projeto tenha todas as bibliotecas necessárias para compilar e rodar, independentemente do ambiente.
- **Exemplo de Conteúdo**: Arquivos de bibliotecas externas.