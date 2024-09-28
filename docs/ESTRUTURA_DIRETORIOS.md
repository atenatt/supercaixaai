# Estrutura de Diretórios do SuperCaixa AI 🗂️

Este documento descreve a estrutura de diretórios do projeto **SuperCaixa AI**, explicando brevemente o propósito de cada pasta e arquivo presente no repositório.

## 📁 Diretórios Principais

```bash
/pdv
│
├── /scripts
│   ├── /funcs                  
│   │   ├── abrir_caixa.sh             # Script para abrir o caixa
│   │   ├── autenticar_usuario.sh       # Script para autenticação de usuários
│   │   ├── cadastrar_mercadoria.sh     # Script para cadastro de mercadorias
│   │   ├── cadastrar_usuario.sh        # Script para cadastro de novos usuários
│   │   ├── criar_promocao.sh           # Script para criar promoções com data de expiração
│   │   ├── editar_mercadoria.sh        # Script para editar informações de mercadorias cadastradas
│   │   ├── excluir_mercadoria.sh       # Script para excluir mercadorias do sistema
│   │   ├── excluir_usuario.sh          # Script para excluir usuários cadastrados
│   │   ├── consultar_mercadoria.sh     # Script para consultar mercadorias específicas
│   │   ├── consultar_todos_usuarios.sh # Script para listar todos os usuários cadastrados
│   │   ├── consultar_logs.sh           # Script para visualizar logs de ações realizadas
│   │   ├── backup_banco.sh             # Script para realizar backup do banco de dados Redis
│   │   ├── registrar_logs.sh           # Função para registrar logs de ações críticas
│   │   └── ...                         # Outros scripts para funções adicionais
│   └── pdv_interface.sh                # Interface principal que gerencia o menu do PDV e chama as funções
├── Dockerfile.pdv                      # Dockerfile para buildar o container do PDV
└── /services
    ├── monitorar_promocoes.service     # Serviço de monitoramento de promoções, rodando em background
```

## 📄 Descrição dos Arquivos

- **/scripts/funcs/**: Esta pasta contém **todos os scripts modularizados** do projeto, permitindo fácil manutenção e adição de novas funcionalidades. Cada funcionalidade do sistema possui um script individual, o que facilita a identificação de bugs e a extensão de funcionalidades.

- **/scripts/pdv_interface.sh**: O arquivo principal que controla a interface do sistema PDV. Ele gerencia o menu principal, o menu administrativo e faz as chamadas necessárias para os scripts em `/funcs`.

- **/services/monitorar_promocoes.service**: Arquivo responsável por definir o **serviço de monitoramento de promoções**. Ele garante que as promoções criadas sejam verificadas continuamente e restauradas após a expiração.

- **Dockerfile.pdv**: Este arquivo Docker define a **imagem do container do PDV**, instalando todas as dependências e configurando os scripts para execução dentro do ambiente.
