---
name: spec-driven-development
description: "Cria especificações antes de codificar. Use ao iniciar um novo projeto, funcionalidade ou mudança significativa quando ainda não existe especificação. Use ao redigir um PRD ou documento de requisitos com objetivos e escopo, ou quando os requisitos estão pouco claros, ambíguos, ou existem apenas como uma ideia vaga. Use quando um único requisito abrange várias capacidades testáveis de forma independente e precisa ser decomposto em um mapa de capacidades (módulos) antes de ser especificado."
---

# Desenvolvimento Orientado por Especificação

## Visão Geral

Escreva uma especificação estruturada antes de escrever qualquer código. A especificação é a fonte de verdade compartilhada entre você e o engenheiro humano — ela define o que estamos construindo, por quê, e como saberemos que está pronto. Código sem especificação é chute.

## Quando Usar

- Iniciando um novo projeto ou funcionalidade
- Requisitos ambíguos ou incompletos
- A mudança toca múltiplos arquivos ou módulos
- Você está prestes a tomar uma decisão de arquitetura
- A tarefa levaria mais de 30 minutos para ser implementada

**Quando NÃO usar:** correções de uma linha, correções de typo, ou mudanças em que os requisitos são inequívocos e autocontidos.

## O Fluxo com Portões (Gates)

O desenvolvimento orientado por especificação tem quatro fases, precedidas por uma checagem de escopo (Fase 0) que só é ativada quando uma única solicitação reúne várias capacidades testáveis de forma independente. Não avance para a próxima fase até que a atual esteja validada.

```
ESPECIFICAR ──→ PLANEJAR ──→ TAREFAS ──→ IMPLEMENTAR
     │             │           │             │
     ▼             ▼           ▼             ▼
  Humano         Humano      Humano        Humano
  revisa         revisa      revisa        revisa
```

### Fase 0: Checagem de Escopo

A maioria das solicitações descreve uma única capacidade. Se for o caso desta, pule esta fase e vá direto para Especificar — a Fase 0 existe para a exceção, não para a regra, e não impõe hierarquia sobre funcionalidades de capacidade única.

**Detecção.** Decomponha antes de especificar quando um único requisito reúne várias capacidades testáveis de forma independente:

- O requisito nomeia capacidades distintas com seus próprios consumidores ou dados (ex.: identidade, cobrança, notificações, relatórios)
- Os critérios de aceitação se agrupam em blocos que poderiam ser entregues e verificados separadamente
- Uma capacidade poderia ser cortada ou substituída sem reescrever os requisitos das outras

**Proponha um mapa de capacidades antes de escrever qualquer especificação.** Pequeno e revisável — uma tabela de módulos mais uma ordem de construção, não um plano de projeto:

```markdown
# Mapa de Capacidades: [Nome da Iniciativa]

| Id do módulo | Responsabilidade | Depende de |
|---|---|---|
| identidade | Contas, sessões, SSO | — |
| cobranca | Planos, faturas, pagamentos | identidade |
| notificacoes | Disparo de e-mail e webhook | identidade |
| relatorios | Dashboards de uso | cobranca, notificacoes |

Ordem de construção: identidade → cobranca, notificacoes → relatorios
```

- **Ids de módulo estáveis.** Kebab-case, escolhidos uma vez, nunca renomeados no meio da iniciativa. Especificações, planos e comandos posteriores selecionam o trabalho por esses ids em vez de adivinhar qual especificação está ativa.
- **Direção de dependência, sem ciclos.** As setas apontam para um único sentido. Se dois módulos precisam um do outro, eles são um único módulo.
- **Interfaces vivem na fronteira.** O mapa registra que `cobranca` depende de `identidade`; o contrato entre eles pertence à especificação do módulo provedor (veja `api-and-interface-design` para projetá-lo — inclusive com exemplos em PHP e Go).

**O mapa passa pelo mesmo portão que qualquer outra fase.** O humano revisa os limites dos módulos, a direção de dependência e a ordem de construção antes de qualquer especificação de módulo ser escrita. Errar o mapa é caro; revisar dez linhas não é.

**Depois, recorra por módulo.** Rode Especificar → Planejar → Tarefas → Implementar para cada módulo, na ordem de dependência. Cada módulo recebe sua própria especificação, delimitada ao objetivo, aos limites e aos critérios de sucesso daquele módulo. Salve o mapa aprovado na raiz do projeto e a especificação de cada módulo ao lado dele, nomeada pelo id do módulo (`SPEC-identidade.md`, `SPEC-cobranca.md`) — o mapa, e não a adivinhação de nome de arquivo, é o índice do que existe.

### Fase 1: Especificar

Comece com uma visão de alto nível. Faça perguntas de esclarecimento ao humano até que os requisitos fiquem concretos.

**Exponha as suposições imediatamente.** Antes de escrever qualquer conteúdo da especificação, liste o que você está assumindo:

```
SUPOSIÇÕES QUE ESTOU FAZENDO:
1. Isso é uma API/aplicação web (não um app mobile nativo)
2. A autenticação usa sessão via cookie ou token (não OAuth externo)
3. O banco de dados é PostgreSQL/MySQL (com base no schema existente)
4. A API PHP roda em PHP 8.2+ / o serviço Go usa a versão do módulo em go.mod
→ Me corrija agora ou eu prossigo com essas suposições.
```

Não preencha silenciosamente requisitos ambíguos. Todo o propósito da especificação é expor mal-entendidos *antes* de o código ser escrito — suposições são a forma mais perigosa de mal-entendido.

**Escreva um documento de especificação cobrindo estas seis áreas centrais:**

1. **Objetivo** — O que estamos construindo e por quê? Quem é o usuário? Como é o sucesso?

2. **Comandos** — Comandos executáveis completos, com flags, não só nomes de ferramenta.

   **PHP (com Composer):**
   ```
   Instalar dependências: composer install
   Testar: composer test  (ou: vendor/bin/phpunit --coverage-text)
   Análise estática: composer stan  (ou: vendor/bin/phpstan analyse)
   Lint/estilo: composer cs-fix  (ou: vendor/bin/php-cs-fixer fix)
   Servidor local: php -S localhost:8000 -t public
   ```

   **Go:**
   ```
   Build: go build ./...
   Testar: go test ./... -cover
   Vet/lint: go vet ./... && golangci-lint run
   Rodar local: go run ./cmd/api
   ```

3. **Estrutura do Projeto** — Onde fica o código-fonte, onde ficam os testes, onde fica a documentação.

   **PHP (ex.: Laravel/Symfony-like):**
   ```
   src/               → Código-fonte da aplicação
   src/Domain         → Entidades e regras de negócio
   src/Http           → Controllers, middlewares, requests
   src/Infrastructure → Repositórios, integrações externas
   tests/Unit         → Testes unitários
   tests/Feature      → Testes de integração/feature
   docs/              → Documentação
   ```

   **Go:**
   ```
   cmd/api/       → Ponto de entrada (main.go) do serviço
   internal/      → Código privado da aplicação (domínio, handlers, repositórios)
   pkg/           → Código destinado a reuso por outros módulos
   *_test.go      → Testes ao lado do código que testam (convenção Go)
   docs/          → Documentação
   ```

4. **Estilo de Código** — Um trecho de código real mostrando seu estilo vale mais que três parágrafos descrevendo-o. Inclua convenções de nomenclatura, regras de formatação e exemplos de saída correta (em PHP, siga PSR-12 e `declare(strict_types=1)`; em Go, siga `gofmt`/`go vet` e as convenções idiomáticas de nomenclatura exportada/não exportada).

5. **Estratégia de Testes** — Qual framework (PHPUnit/Pest em PHP; o pacote `testing` nativo em Go), onde os testes ficam, expectativa de cobertura, quais níveis de teste para quais preocupações.

6. **Limites** — Sistema de três níveis:
   - **Sempre fazer:** rodar os testes antes de commits, seguir as convenções de nomenclatura, validar inputs
   - **Perguntar antes:** mudanças de schema de banco de dados, adicionar dependências (`composer require`, `go get`), mudar configuração de CI
   - **Nunca fazer:** commitar segredos, editar diretórios de dependências (`vendor/` em PHP, o cache de módulos em Go), remover testes que estão falhando sem aprovação

**Modelo de especificação:**

```markdown
# Especificação: [Nome do Projeto/Funcionalidade]

## Objetivo
[O que estamos construindo e por quê. Histórias de usuário ou critérios de aceitação.]

## Stack Técnica
[Linguagem (PHP/Go), framework, principais dependências com versões]

## Comandos
[Build, teste, lint, execução local — comandos completos]

## Estrutura do Projeto
[Layout de diretórios com descrições]

## Estilo de Código
[Trecho de exemplo + convenções principais]

## Estratégia de Testes
[Framework, onde ficam os testes, requisitos de cobertura, níveis de teste]

## Limites
- Sempre: [...]
- Perguntar antes: [...]
- Nunca: [...]

## Critérios de Sucesso
[Como saberemos que está pronto — condições específicas e testáveis]

## Questões em Aberto
[Qualquer coisa não resolvida que precise de input humano]
```

**Ferramentas externas de especificação:** este fluxo é agnóstico de formato. Se o projeto já usa OpenSpec ou outro sistema de especificação, mantenha o formato de artefato e as convenções de armazenamento desse sistema em vez de criar um `SPEC.md` duplicado. Esta skill é dona da clarificação, do conteúdo e dos portões de aprovação; a ferramenta externa é dona de como a especificação aprovada é representada.

**Reformule instruções como critérios de sucesso.** Ao receber requisitos vagos, traduza-os em condições concretas:

```
REQUISITO: "Deixa a listagem de pedidos mais rápida"

CRITÉRIOS DE SUCESSO REFORMULADOS:
- Endpoint GET /api/orders responde em < 300ms no p95, com 1000 registros
- Sem consultas N+1 no carregamento da listagem
- Paginação obrigatória, com no máximo 50 itens por página
→ Esses são os alvos corretos?
```

Isso permite iterar, tentar de novo e resolver problemas em direção a um objetivo claro em vez de adivinhar o que "mais rápido" significa.

### Fase 2: Planejar

Com a especificação validada, gere um plano técnico de implementação:

1. Identifique os componentes principais e suas dependências
2. Determine a ordem de implementação (o que precisa ser construído primeiro)
3. Anote riscos e estratégias de mitigação
4. Identifique o que pode ser construído em paralelo vs. o que precisa ser sequencial
5. Defina pontos de verificação entre as fases

> Siga `planning-and-task-breakdown` para o mapeamento de grafo de dependências e a mecânica de fatiamento vertical por trás destes passos; ela é a fonte canônica. Os itens acima são um resumo leve; se algum dia divergirem, `planning-and-task-breakdown` prevalece.
>
> **Convenção de saída:** salve o plano em `tasks/plan.md` e registre a lista de tarefas no destino definido por `planning-and-task-breakdown` (padrão `tasks/todo.md`; projetos podem designar um tracker externo). Crie `tasks/` se não existir. Comandos posteriores (`/build`, etc.) esperam esses padrões.

O plano deve ser revisável: o humano deve conseguir lê-lo e dizer "sim, essa é a abordagem certa" ou "não, mude X."

### Fase 3: Tarefas

Divida o plano em tarefas discretas e implementáveis:

- Cada tarefa deve ser completável em uma única sessão de foco
- Cada tarefa tem critérios de aceitação explícitos
- Cada tarefa inclui um passo de verificação (teste, build, checagem manual)
- As tarefas são ordenadas por dependência, não por importância percebida
- Nenhuma tarefa deve exigir a mudança de mais de ~5 arquivos

> Siga `planning-and-task-breakdown` para a mecânica completa de dimensionamento e ordenação por dependência de tarefas; ela é a fonte canônica. O modelo abaixo é uma forma inline leve; se algum dia divergirem, `planning-and-task-breakdown` prevalece.

**Modelo de tarefa:**
```markdown
- [ ] Tarefa: [Descrição]
  - Aceitação: [O que precisa ser verdade quando concluída]
  - Verificação: [Como confirmar — comando de teste, build, checagem manual]
  - Arquivos: [Quais arquivos serão tocados]
```

### Fase 4: Implementar

Execute as tarefas uma de cada vez seguindo `skills/incremental-implementation/SKILL.md` (`incremental-implementation`) e `skills/tdd/SKILL.md` (`tdd`). Use `skills/context-engineering/SKILL.md` (`context-engineering`) para carregar as seções certas da especificação e os arquivos-fonte certos a cada passo, em vez de inundar o agente com a especificação inteira.

## Mantendo a Especificação Viva

A especificação é um documento vivo, não um artefato de uma única vez:

- **Atualize quando decisões mudarem** — Se você descobrir que o modelo de dados precisa mudar, atualize a especificação primeiro, depois implemente.
- **Atualize quando o escopo mudar** — Funcionalidades adicionadas ou cortadas devem ser refletidas na especificação.
- **Faça commit da especificação** — A especificação pertence ao controle de versão, junto com o código.
- **Referencie a especificação nos PRs** — Aponte de volta para a seção da especificação que cada PR implementa.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Isso é simples, não preciso de especificação" | Tarefas simples não precisam de especificações *longas*, mas ainda precisam de critérios de aceitação. Uma especificação de duas linhas está ótima. |
| "Escrevo a especificação depois que codificar" | Isso é documentação, não especificação. O valor da especificação está em forçar clareza *antes* do código. |
| "A especificação vai nos atrasar" | Uma especificação de 15 minutos evita horas de retrabalho. Cascata em 15 minutos vale mais que debugar por 15 horas. |
| "Os requisitos vão mudar de qualquer jeito" | É por isso que a especificação é um documento vivo. Uma especificação desatualizada ainda é melhor que nenhuma especificação. |
| "O usuário sabe o que quer" | Até pedidos claros têm suposições implícitas. A especificação expõe essas suposições. |
| "É uma funcionalidade grande só; dividir é overhead" | Se os critérios de aceitação se agrupam em blocos testáveis de forma independente, uma especificação monolítica força toda tarefa posterior a raciocinar sobre o contrato inteiro. Um mapa de capacidades de dez linhas é a alternativa barata. |
| "Eu decomponho durante o planejamento" | O planejamento fatia tarefas dentro de uma especificação. Nessa altura o artefato superdimensionado já existe — os limites dos módulos e a direção de dependência precisam ser decididos antes de a especificação ser escrita, não depois. |

## Sinais de Alerta

- Começar a escrever código sem nenhum requisito registrado
- Perguntar "eu já começo a construir?" antes de esclarecer o que "pronto" significa
- Implementar funcionalidades não mencionadas em nenhuma especificação ou lista de tarefas
- Tomar decisões de arquitetura sem documentá-las
- Pular a especificação porque "é óbvio o que construir"
- Uma única especificação cujos requisitos abrangem várias capacidades testáveis de forma independente
- Limites de módulo ou ordem de construção decididos implicitamente durante a implementação porque nenhum mapa de capacidades foi aprovado antecipadamente

## Verificação

Antes de avançar para a implementação, confirme:

- [ ] A especificação cobre as seis áreas centrais
- [ ] O humano revisou e aprovou a especificação
- [ ] Os critérios de sucesso são específicos e testáveis
- [ ] Os limites (Sempre/Perguntar Antes/Nunca) estão definidos
- [ ] A especificação está salva em um arquivo no repositório
- [ ] Se a solicitação reúne várias capacidades testáveis de forma independente, um mapa de capacidades (ids de módulo, direção de dependência, ordem de construção) foi aprovado antes de qualquer especificação de módulo ser escrita
- [ ] Toda especificação de módulo remete a um id de módulo do mapa aprovado
