---
name: planning-and-task-breakdown
description: "Divide o trabalho em tarefas ordenadas. Use quando você tem uma especificação ou requisitos claros e precisa dividir o trabalho em tarefas implementáveis. Use quando uma tarefa parece grande demais para começar, quando precisa estimar o escopo, ou quando é possível trabalhar em paralelo."
---

# Planejamento e Divisão de Tarefas

## Visão Geral

Decomponha o trabalho em tarefas pequenas e verificáveis, com critérios de aceitação explícitos. Uma boa divisão de tarefas é a diferença entre um agente que entrega trabalho de forma confiável e um que produz uma bagunça emaranhada. Toda tarefa deve ser pequena o suficiente para ser implementada, testada e verificada em uma única sessão de foco.

## Quando Usar

- Você tem uma especificação e precisa dividi-la em unidades implementáveis
- Uma tarefa parece grande ou vaga demais para começar
- O trabalho precisa ser paralelizado entre múltiplos agentes ou sessões
- Você precisa comunicar o escopo a um humano
- A ordem de implementação não é óbvia

**Quando NÃO usar:** mudanças de arquivo único com escopo óbvio, ou quando a especificação já contém tarefas bem definidas.

## O Processo de Planejamento

### Passo 1: Entre em Modo de Planejamento

Antes de escrever qualquer código, opere em modo somente leitura:

- Leia a especificação e as seções relevantes da base de código
- Identifique padrões e convenções existentes
- Mapeie as dependências entre componentes
- Anote riscos e incógnitas

**NÃO escreva código durante o planejamento.** O resultado é um documento de plano salvo em `tasks/plan.md` e uma lista de tarefas registrada no destino da lista de tarefas (veja Arquivos de Saída; padrão `tasks/todo.md`), não implementação.

### Passo 2: Identifique o Grafo de Dependências

Mapeie o que depende do quê:

```
Schema do banco de dados
    │
    ├── Modelos/tipos da API (structs em Go, DTOs/entidades em PHP)
    │       │
    │       ├── Endpoints da API
    │       │       │
    │       │       └── Cliente HTTP do frontend / consumidor da API
    │       │               │
    │       │               └── Componentes de UI
    │       │
    │       └── Lógica de validação
    │
    └── Dados de seed / migrations
```

A ordem de implementação segue o grafo de dependências de baixo para cima: construa as fundações primeiro.

### Passo 3: Fatie Verticalmente

Em vez de construir todo o banco de dados, depois toda a API, depois toda a UI — construa um caminho completo de funcionalidade por vez:

**Ruim (fatiamento horizontal):**
```
Tarefa 1: Construir o schema inteiro do banco de dados
Tarefa 2: Construir todos os endpoints da API
Tarefa 3: Construir todos os componentes de UI
Tarefa 4: Conectar tudo
```

**Bom (fatiamento vertical):**
```
Tarefa 1: Usuário consegue criar uma conta (schema + API + UI de cadastro)
Tarefa 2: Usuário consegue fazer login (schema de auth + API + UI de login)
Tarefa 3: Usuário consegue criar uma tarefa (schema de tarefa + API + UI de criação)
Tarefa 4: Usuário consegue ver a lista de tarefas (query + API + UI de listagem)
```

Cada fatia vertical entrega funcionalidade que funciona e é testável.

### Passo 4: Escreva as Tarefas

Cada tarefa segue esta estrutura, seja ela registrada na lista de tarefas em markdown ou como um item em um tracker externo (veja Arquivos de Saída):

```markdown
## Tarefa [N]: [Título curto e descritivo]

**Descrição:** Um parágrafo explicando o que essa tarefa realiza.

**Critérios de aceitação:**
- [ ] [Condição específica e testável]
- [ ] [Condição específica e testável]

**Verificação:**
- [ ] Testes passam: [o comando de teste focado do repositório]
- [ ] Build funciona: [o comando de build do repositório]
- [ ] Checagem manual: [descrição do que verificar]

**Dependências:** [Números das tarefas das quais esta depende, ou "Nenhuma"]

**Arquivos provavelmente tocados:**

*Exemplo em PHP:*
- `src/Domain/Task/TaskService.php`
- `tests/Unit/Domain/Task/TaskServiceTest.php`

*Exemplo em Go:*
- `internal/task/service.go`
- `internal/task/service_test.go`

**Escopo estimado:** [Pequeno: 1-2 arquivos | Médio: 3-5 arquivos | Grande: 5+ arquivos]
```

### Passo 5: Ordene e Defina Checkpoints

Organize as tarefas de forma que:

1. As dependências estejam satisfeitas (construa a fundação primeiro)
2. Cada tarefa deixe o sistema em um estado funcional
3. Pontos de verificação ocorram a cada 2-3 tarefas
4. Tarefas de alto risco fiquem no início (falhe rápido)

Adicione checkpoints explícitos ao destino da lista de tarefas:

```markdown
## Checkpoint: Depois das Tarefas 1-3
- [ ] Todos os testes passam
- [ ] A aplicação builda sem erros
- [ ] O fluxo principal do usuário funciona de ponta a ponta
- [ ] Revisão com o humano antes de prosseguir
```

## Diretrizes de Dimensionamento de Tarefas

| Tamanho | Arquivos | Escopo | Exemplo |
|------|-------|-------|---------|
| **XS** | 1 | Função única ou mudança de configuração | Adicionar uma regra de validação |
| **S** | 1-2 | Um componente ou endpoint | Adicionar um novo endpoint de API |
| **M** | 3-5 | Uma fatia de funcionalidade | Fluxo de cadastro de usuário |
| **L** | 5-8 | Funcionalidade com múltiplos componentes | Busca com filtro e paginação |
| **XL** | 8+ | **Grande demais — divida ainda mais** | — |

Se uma tarefa é L ou maior, ela deve ser dividida em tarefas menores. Um agente tem melhor desempenho em tarefas S e M.

**Quando dividir uma tarefa ainda mais:**
- Levaria mais de uma sessão de foco (aproximadamente 2+ horas de trabalho do agente)
- Você não consegue descrever os critérios de aceitação em 3 ou menos itens
- Ela toca dois ou mais subsistemas independentes (ex.: autenticação e cobrança)
- Você percebe que está escrevendo "e" no título da tarefa (sinal de que são duas tarefas)

## Arquivos de Saída

- **Documento de plano:** salve o plano de implementação em `tasks/plan.md`. Isso é sempre um arquivo markdown — decisões de design, riscos e questões em aberto não mapeiam de forma limpa para itens individuais de tracker.
- **Lista de tarefas:** registre cada tarefa no **destino da lista de tarefas** (definido abaixo).

Crie o diretório `tasks/` se ele não existir.

**Nunca sobrescreva um plano incompleto.** Antes de escrever em `tasks/plan.md` ou `tasks/todo.md`, verifique se eles já existem e ainda contêm tarefas não marcadas:

- Mesmo trabalho sendo replanejado (o usuário pediu para revisar ou estender este plano) → atualize os arquivos existentes no lugar.
- Trabalho diferente → **pare e pergunte.** As tarefas não marcadas podem estar em construção em outra sessão. Não apague, sobrescreva ou renomeie os arquivos existentes por conta própria; apresente o conflito e deixe o usuário decidir (terminar o plano antigo primeiro, descartá-lo explicitamente, ou dizer onde o novo plano deve ir).

A mesma regra se aplica a um destino de lista de tarefas externo: nunca feche em massa ou apague itens em aberto do tracker de outro plano para abrir espaço para novos.

### Destino da Lista de Tarefas

O destino da lista de tarefas é onde tarefas e checkpoints são registrados. Ele é definido uma única vez, aqui; toda outra referência nesta skill remete a ele.

- **Padrão: um arquivo markdown em formato de checklist em `tasks/todo.md`.** Essa é a convenção que o comando `/build` e outras ferramentas posteriores esperam. Use-a a menos que o projeto diga o contrário.
- **Tracker externo:** se as regras de agente do projeto (`CLAUDE.md`, `AGENTS.md`, etc.) ou o usuário designarem um tracker de issues (ex.: GitHub Issues, Jira, Linear, `bd`/beads), crie um item de tracker por tarefa em vez de escrever `tasks/todo.md`. Mapeie a estrutura do Passo 4 para os campos do tracker: critérios de aceitação e passos de verificação no corpo do item, dependências via o mecanismo de vínculo do tracker (`bd dep add`, "blocked by", etc.). Registre os checkpoints do Passo 5 também como itens de tracker, ou como uma checklist no documento de plano, caso o tracker não tenha um equivalente natural.

Ao usar um tracker externo, anote isso em `tasks/plan.md` (ex.: "Tarefas rastreadas no projeto FOO do Linear") para que passos posteriores e sessões futuras saibam onde procurar, e mantenha a seção de Lista de Tarefas do documento de plano como um índice ordenado de IDs ou links de itens do tracker, em vez de uma checklist duplicada.

## Modelo do Documento de Plano

```markdown
# Plano de Implementação: [Nome da Funcionalidade/Projeto]

## Visão Geral
[Um parágrafo resumindo o que estamos construindo]

## Decisões de Arquitetura
- [Decisão-chave 1 e justificativa]
- [Decisão-chave 2 e justificativa]

## Lista de Tarefas

### Fase 1: Fundação
- [ ] Tarefa 1: ...
- [ ] Tarefa 2: ...

### Checkpoint: Fundação
- [ ] Testes passam, build limpo

### Fase 2: Funcionalidades Principais
- [ ] Tarefa 3: ...
- [ ] Tarefa 4: ...

### Checkpoint: Funcionalidades Principais
- [ ] Fluxo de ponta a ponta funciona

### Fase 3: Polimento
- [ ] Tarefa 5: ...
- [ ] Tarefa 6: ...

### Checkpoint: Completo
- [ ] Todos os critérios de aceitação atendidos
- [ ] Pronto para revisão

## Riscos e Mitigações
| Risco | Impacto | Mitigação |
|------|--------|------------|
| [Risco] | [Alto/Médio/Baixo] | [Estratégia] |

## Questões em Aberto
- [Questão que precisa de input humano]
```

Quando as tarefas vivem em um tracker externo, mantenha a seção de Lista de Tarefas acima como um índice ordenado de IDs ou links de itens do tracker, em vez de uma checklist duplicada.

## Oportunidades de Paralelização

Quando múltiplos agentes ou sessões estão disponíveis:

- **Seguro para paralelizar:** fatias de funcionalidade independentes, testes para funcionalidades já implementadas, documentação
- **Precisa ser sequencial:** migrations de banco de dados, mudanças de estado compartilhado, cadeias de dependência
- **Precisa de coordenação:** funcionalidades que compartilham um contrato de API (defina o contrato primeiro — veja `api-and-interface-design` — depois paralelize)

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Eu resolvo isso no caminho" | É assim que você acaba com uma bagunça emaranhada e retrabalho. 10 minutos de planejamento economizam horas. |
| "As tarefas são óbvias" | Escreva-as mesmo assim. Tarefas explícitas expõem dependências ocultas e casos de borda esquecidos. |
| "Planejar é overhead" | Planejar é a tarefa. Implementação sem plano é só digitar. |
| "Eu consigo guardar tudo na cabeça" | Janelas de contexto são finitas. Planos escritos sobrevivem a limites de sessão e à compactação. |
| "O `tasks/plan.md` antigo está desatualizado, vou simplesmente substituir" | Tarefas não marcadas podem estar em construção em outra sessão. Sobrescrevê-las destrói um estado de trabalho que não existe em nenhum outro lugar. Pare e pergunte. |

## Sinais de Alerta

- Começar a implementação sem uma lista de tarefas escrita
- Sobrescrever um `tasks/plan.md` ou `tasks/todo.md` que ainda tem tarefas não marcadas de um trabalho diferente, sem perguntar
- Escrever `tasks/todo.md` quando o projeto já designou um tracker externo (ou espalhar tarefas entre os dois)
- Tarefas que dizem "implementar a funcionalidade" sem critérios de aceitação
- Nenhum passo de verificação no plano
- Todas as tarefas são de tamanho XL
- Nenhum checkpoint entre as tarefas
- A ordem de dependência não é considerada

## Verificação

Antes de iniciar a implementação, confirme:

- [ ] Toda tarefa tem critérios de aceitação
- [ ] Toda tarefa tem um passo de verificação
- [ ] As dependências entre tarefas foram identificadas e ordenadas corretamente
- [ ] As tarefas estão registradas no destino da lista de tarefas (padrão `tasks/todo.md`)
- [ ] Nenhum plano incompleto pré-existente foi sobrescrito sem confirmação explícita do usuário
- [ ] Nenhuma tarefa toca mais de ~5 arquivos
- [ ] Existem checkpoints entre as fases principais
- [ ] O humano revisou e aprovou o plano

## Veja Também

Critérios de aceitação são por tarefa e respondem "construímos a coisa certa?". Eles ficam acima da Definição de Pronto (Definition of Done) de todo o projeto, o padrão permanente que toda tarefa precisa atender para contar como concluída. Veja `../../references/definition-of-done.md`.
