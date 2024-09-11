# Padrões de Commit e Branches - SuperCaixa AI

Este documento descreve as regras e padrões a serem seguidos ao fazer commits e gerenciar branches no repositório do **SuperCaixa AI**. Mesmo sendo um projeto solo, manter esses padrões garantirá que o histórico de mudanças seja limpo, organizado e fácil de seguir.

## Padrões de Commits

Utilizaremos um formato de commit semântico, inspirado no **Conventional Commits**, que facilita a leitura e a compreensão do histórico do projeto. Os commits terão uma estrutura específica para descrever a mudança de forma clara e concisa.

### Formato Básico de Commit:

```
<tipo>: <descrição curta>
```

- **tipo**: Define a categoria da mudança.
- **descrição curta**: Explica, de forma objetiva e em menos de 50 caracteres, o que foi alterado.

### Tipos de Commit:

- **feat**: Usado para a adição de uma nova funcionalidade.
  - Exemplo: `feat: adiciona caso de uso para registrar venda`
  
- **fix**: Usado para correção de bugs ou problemas existentes.
  - Exemplo: `fix: corrige erro na emissão de relatórios`
  
- **docs**: Usado para mudanças na documentação (ex.: README, ARQUITETURA.md, etc.).
  - Exemplo: `docs: adiciona guia de instalação no SETUP.md`
  
- **style**: Usado para mudanças relacionadas ao estilo do código (formatação, espaçamento, etc.), sem impactar o comportamento.
  - Exemplo: `style: ajusta formatação de código em vendas.go`
  
- **refactor**: Usado para refatoração de código, como melhorias internas, sem alterar o comportamento existente.
  - Exemplo: `refactor: otimiza lógica de cálculo de vendas`
  
- **test**: Usado para a adição ou correção de testes automatizados.
  - Exemplo: `test: adiciona testes unitários para registrar venda`
  
- **chore**: Usado para mudanças gerais que não impactam diretamente o código (ex.: atualizações de dependências, scripts de build).
  - Exemplo: `chore: atualiza dependências do Go Modules`

### Descrição Expandida (Opcional):

Se necessário, você pode adicionar uma descrição expandida no commit para fornecer mais contexto sobre a mudança:

```bash
git commit
```

No editor que abrir, insira o resumo no topo e a descrição expandida abaixo:

```
feat: adiciona suporte a relatórios de vendas

- Implementa funcionalidade para gerar relatórios detalhados de vendas diárias
- Adiciona filtros por período e por cliente
```

## Padrões de Branches

Vamos seguir um fluxo de branches simples, baseado em **Git Flow**, que facilita o gerenciamento de diferentes estágios do desenvolvimento e a adição de novas funcionalidades.

### Branches Principais:

- **main**: Branch principal, que sempre contém a versão estável e funcional do sistema.
- **develop**: Branch de desenvolvimento, onde as novas funcionalidades são integradas e testadas antes de serem mescladas na `main`.

### Branches de Funcionalidades:

Para cada nova funcionalidade ou correção, uma branch específica será criada, e a nomenclatura deve seguir o padrão abaixo:

```
<tipo>/<descrição-da-mudança>
```

- **tipo**: Pode ser `feat`, `fix`, `refactor`, etc., seguindo a mesma lógica dos commits.
- **descrição-da-mudança**: Uma breve descrição da funcionalidade ou correção.

### Exemplo de Nome de Branch:
- Para adicionar a funcionalidade de "registrar venda":
  ```
  feat/registrar-venda
  ```

- Para corrigir um erro na "emissão de relatórios":
  ```
  fix/erro-emissao-relatorios
  ```