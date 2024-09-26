Aqui está o conteúdo do arquivo `README.md` para o diretório `/pdv` com um tom descontraído e informativo, explicando os principais pontos dos scripts e funcionalidades que você implementou:

---

# 🛒 SuperCaixa AI - PDV

Bem-vindo ao **SuperCaixa AI - PDV**! 🎉 Este projeto é um PDV inteligente e modular, cheio de funcionalidades úteis para gerenciamento de mercadorias, usuários, setores e promoções. Tudo isso em um ambiente super clean e funcional. Abaixo você encontrará uma visão geral sobre o que cada script faz e como tudo foi montado!

## 📁 Estrutura dos Scripts

### 📜 **pdv_interface.sh**
Este é o **comando mestre**! Ele controla todo o menu do PDV e garante que você tenha acesso a todas as funcionalidades de forma centralizada. Nele, você pode:
- **Abrir Caixa**
- **Consultar Mercadoria**
- **Acessar o Menu Administrativo**, que inclui cadastro de mercadorias, usuários, setores, promoções e até backup do banco de dados!

O `pdv_interface.sh` carrega automaticamente as funções de todos os scripts da pasta `funcs`, exceto o script de monitoramento de promoções (explicaremos isso mais tarde). É o cérebro da operação! 🧠

### 🛠 **Scripts Principais (pasta funcs)**

Aqui está o que cada um dos scripts faz:

#### 🔐 **autenticar_usuario.sh**
Esse carinha é responsável por garantir que ninguém acesse funções que não deveria. Ele pede login e senha, verifica o papel do usuário (admin, fiscal ou operador) e libera o acesso conforme o perfil. Segurança em primeiro lugar! 🔒

#### 📦 **cadastrar_mercadoria.sh**
Aqui você pode cadastrar mercadorias com **Código GTIN**, **Código Interno**, preço de custo, preço de venda, estoque e até associar a um setor específico. Tudo isso numa única tela, de forma fácil e rápida. Se o item não tiver setor? Não rola o cadastro! 😉

#### 👤 **cadastrar_usuario.sh**
Precisa adicionar novos operadores, fiscais ou administradores? Este é o script certo. Ele cria novos usuários no sistema com suas respectivas funções e senha. Tudo prático e direto.

#### 🗂 **criar_setor.sh**
Organize seu supermercado! Você pode criar setores (como "Frios" e "Hortifrúti") para classificar suas mercadorias e deixar tudo mais organizado. 🥶🍏

#### ✂️ **excluir_mercadoria.sh**
Chegou a hora de dar adeus a uma mercadoria? Este script permite excluir mercadorias cadastradas. Mas só administradores podem fazer isso, claro. 🔨

#### ❌ **excluir_usuario.sh**
Este é sério! Aqui você exclui usuários, mas **nunca** o usuário admin. Quem tem poder de admin, tem poder de permanência! 👑

#### 📑 **consultar_mercadoria.sh**
Simples e eficiente. Você insere o código de barras ou código interno da mercadoria e o script retorna todos os detalhes dela: nome, preço de custo, preço de venda, estoque e setor. 🔍

#### 🛒 **consultar_por_setor.sh**
Quer saber tudo o que está no setor "Frios"? Sem problemas! Esta função consulta todas as mercadorias de um setor específico, exibindo nome, preço, estoque e muito mais. 🍦🥦

#### 🛠 **editar_mercadoria.sh**
Mudança de preço? Estoque foi atualizado? Este script permite editar os detalhes de qualquer mercadoria já cadastrada, de forma rápida e segura.

#### 📝 **consultar_todas_mercadorias.sh**
Exibe todas as mercadorias cadastradas de forma paginada (para não lotar a tela de uma vez). Assim, você pode consultar todos os itens cadastrados e seus respectivos detalhes. 📋

#### 🔥 **criar_promocao.sh**
Um dos mais legais! 🎉 Aqui você pode criar promoções de mercadorias, definindo um novo preço promocional e uma data de expiração, tudo com um calendário interativo. Se o preço da promoção for maior que o original, esquece... Só vale se for menor. E depois da data, o preço volta ao original.

#### 🎛 **consultar_promocao.sh**
Aqui você consulta todas as informações de uma promoção ativa: preço promocional, original e até a data de expiração da promoção.

#### 🖥 **monitorar_promocoes.sh**
Este script monitora as promoções que estão ativas e restaura o preço original das mercadorias quando a promoção expira. Ele é executado em segundo plano automaticamente ao iniciar o container do PDV. Nada passa despercebido!

#### 📜 **backup_banco.sh**
Aqui não brincamos com dados! 💾 Este script faz o backup do banco de dados Redis e salva tudo bonitinho em um diretório compartilhado entre os containers. Segurança sempre!

#### 📅 **verificar_ultimo_backup.sh**
Curioso sobre o último backup? Este script te informa quando foi realizado o último backup, dando aquela segurança extra.

#### 📊 **consultar_logs.sh**
Aqui você pode ver os logs de ações dos usuários, como quem cadastrou mercadorias, excluiu itens ou editou preços. Tudo registrado para garantir transparência e controle total do sistema.

---

## 💡 Como rodar o PDV

1. **Suba o ambiente** com `docker-compose up -d`. Isso vai iniciar o web server, o banco de dados Redis e os containers do PDV.
2. **Acesse o container do PDV** para rodar o sistema:
   ```bash
   docker exec -it pdv1 sh
   ```
3. **Execute o PDV**:
   ```bash
   pdv
   ```

E pronto! O sistema estará pronto para ser utilizado! 🎉

---

## 🔮 Futuras Implementações

- **Futuras funcionalidades** estão reservadas para crescimento contínuo do sistema.
- Mais automações e monitoramento para tornar o SuperCaixa AI cada vez mais inteligente.

---

### Conclusão

Este projeto evoluiu muito e está robusto o suficiente para gerenciar uma grande quantidade de mercadorias, usuários e promoções, tudo com segurança e eficiência. E o mais importante: **feito com muito café ☕ e código limpo**!

Se tiver sugestões ou encontrar algum bug, sinta-se à vontade para ajustar, melhorar e colaborar!

---

Que tal rodar o **SuperCaixa AI** e ver ele em ação? 🚀