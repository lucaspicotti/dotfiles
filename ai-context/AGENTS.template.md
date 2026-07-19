# AGENTS.md (Nome do Projeto)

> Guia de contribuição técnica para agentes de IA (e humanos) específico deste repositório.

---

## 📌 Visão Geral do Projeto

*Breve resumo do que o projeto faz, principais tecnologias de base e características estruturais críticas.*

* **Linguagem & Framework:** Ex: Ruby on Rails 8, Python/Django 5, TypeScript/Next.js 14
* **Banco de Dados:** Ex: PostgreSQL, Redis (ou "Sem banco de dados / File-system based")
* **Estado/Escopo do Projeto:** Ex: Protótipo em validação, App legado em produção, Monolito modular.

---

## 🛠️ Comandos do Projeto

*Comandos diretos que o agente pode utilizar para configurar, rodar e validar alterações.*

```bash
# Setup inicial do ambiente
<comando_aqui>

# Executar servidor de desenvolvimento local
<comando_aqui>

# Executar a suíte de testes principal
<comando_aqui>

# Executar testes secundários (ex: frontend/backend isolados)
<comando_aqui>

# Executar formatação e linters do código
<comando_aqui>

# Executar ferramentas de análise de segurança / vulnerabilidades
<comando_aqui>
```

---

## 🏗️ Estrutura e Arquitetura

### Backend
*Escreva as principais convenções do backend do projeto, onde residem as regras de negócio e como interagir com dados.*

* **Pasta Chave (`caminho/`)**: Descrição do que faz e convenção de nomenclatura.
* **Pasta Chave (`caminho/`)**: Descrição do que faz e convenção de nomenclatura.
* **Padrões Críticos:**
  * Ex: "Sempre herdar de `ApplicationService` para criar services."
  * Ex: "Nunca instanciar a API externa diretamente, use o Singleton `ApiClient`."

### Frontend
*Descreva a tecnologia de interface, como o estado é gerenciado, onde ficam os assets e regras de estilo.*

* **Pasta Chave (`caminho/`)**: Descrição.
* **Estilização/CSS:** Ex: "Usamos Tailwind. Cores devem seguir estritamente o tema em `tailwind.config.js`."
* **Padrões Críticos:**
  * Ex: "Cada componente interativo deve ter um controller Stimulus correspondente."

---

## 🧪 Práticas de Teste

*Como escrever e validar testes neste repositório específico.*

* **Frameworks Utilizados:** Ex: Minitest (Ruby), Vitest (JS), Pytest (Python).
* **Políticas de Mock/Stub:**
  * Ex: "Faça mock de chamadas de API externa usando `Webmock`. Não faça mock do banco de dados real."
* **Padrões Específicos:**
  * Ex: "Para testar permissões de escrita, use stubs que lancem exceções de I/O em vez de modificar permissões de arquivos."

---

## ✅ Do (O que fazer)

*Diretrizes de boas práticas específicas deste projeto.*

- [ ] Manter os commits atômicos e descritos na ordem do fluxo.
- [ ] Adicionar testes correspondentes para qualquer nova regra de negócio criada.
- [ ] Usar o helper `<NomeHelper>` para realizar `<Ação>`.
- [ ] Seguir o padrão de design `<NomePadrão>` já existente no repositório.

---

## ❌ Don't (O que NÃO fazer)

*Restrições de design e limitações que o agente deve respeitar a todo custo.*

- **Não** leia variáveis de ambiente (`ENV`) diretamente fora do arquivo/classe de configuração.
- **Não** adicione bibliotecas externas ou dependências novas sem justificar a real necessidade.
- **Não** altere arquivos ou configurações estruturais de CI/CD sem autorização explícita do usuário.
- **Não** realize refatorações amplas em arquivos fora do escopo da tarefa solicitada.

---

## 📋 Checklist de Pull Request

*Critérios de aceite técnicos antes de considerar a tarefa como concluída.*

- [ ] Todos os testes locais passam sem regressões.
- [ ] Linters e analisadores estáticos passam sem erros.
- [ ] Não há vazamento de dados sensíveis ou segredos.
- [ ] O código segue o estilo de arquitetura e design descritos neste documento.
