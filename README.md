# SuperCaixa AI

**SuperCaixa AI** é um sistema de Ponto de Venda (PDV) desenvolvido para supermercados, com foco em automação, eficiência e boas práticas de DevOps. O sistema será implementado utilizando **Golang** e **Shell Script**, com containerização, automação via **Ansible** e provisionamento na nuvem usando **Terraform**. O projeto será 100% Linux, com PDVs de baixo custo e a interface de relatórios acessada em sistemas Windows.

## Funcionalidades Principais (Planejadas)
- Registro de mercadorias
- Emissão de relatórios de vendas e clientes
- Controle de estoque em tempo real
- Diferentes níveis de usuários (Administrador, Operadores de Caixa, Gerente, Fiscal)
- Interface intuitiva para fiscais, com foco em UI/UX
- Segurança e proteção contra brechas de segurança

## Tecnologias Utilizadas
- **Linguagens**: Golang, Shell Script
- **Banco de Dados**: NoSQL (preferencialmente) e MariaDB
- **Ferramentas DevOps**: 
  - Ansible (automação e provisionamento)
  - Docker (containerização)
  - Vagrant (provisionamento local)
  - Terraform (provisionamento na nuvem)
  - Jenkins (CI/CD)
  - Nginx (load balancing)
  - Kubernetes (futuro)
  - SonarQube (monitoramento de código)
  
## Estrutura de Desenvolvimento
- **Infraestrutura como Código**: Utilizando Ansible, Docker, e Terraform
- **Sistema Operacional**: Linux (PDVs com Alpine Linux, servidores com Ubuntu/Debian)
- **Desenvolvimento e Testes**: Git e GitHub para controle de versão, Vagrant para ambiente de desenvolvimento

## Roadmap
1. Configuração do ambiente de desenvolvimento e provisionamento local
2. Desenvolvimento das funcionalidades principais (registro de mercadorias, relatórios)
3. Containerização e automação com Ansible
4. Deploy na nuvem usando AWS EC2
5. Implementação de segurança e proteção de dados
6. Escalabilidade com Kubernetes e Nginx

## Contribuição
Este é um projeto pessoal, e o foco é aprendizado contínuo em DevOps e desenvolvimento de sistemas distribuídos. 

## Licença
A definir.
