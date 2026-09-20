---
name: code-review-and-quality
description: "Conduz code review multi-eixo. Use antes de mesclar (merge) qualquer mudança. Use ao revisar código escrito por você mesmo, por outro agente, ou por um humano. Use quando precisar avaliar a qualidade do código em múltiplas dimensões antes de ele entrar na branch principal."
---

# Code Review e Qualidade

## Visão Geral

Code review multidimensional com quality gates. Toda mudança é revisada antes do merge — sem exceções. A revisão cobre cinco eixos: correção, legibilidade, arquitetura, segurança e performance.

**O padrão de aprovação:** aprove uma mudança quando ela definitivamente melhora a saúde geral do código, mesmo que não seja perfeita. Código perfeito não existe — o objetivo é a melhoria contínua. Não bloqueie uma mudança só porque não é exatamente como você mesmo teria escrito. Se ela melhora a base de código e segue as convenções do projeto, aprove.

## Quando Usar

- Antes de mesclar qualquer PR ou mudança
- Depois de concluir a implementação de uma funcionalidade
- Quando outro agente ou modelo produziu código que você precisa avaliar
- Ao refatorar código existente
- Depois de qualquer correção de bug (revise tanto o fix quanto o teste de regressão)

## A Revisão em Cinco Eixos

Toda revisão avalia o código nestas dimensões:

### 1. Correção

O código faz o que diz que faz?

- Está de acordo com a especificação ou os requisitos da tarefa?
- Casos de borda são tratados (nulo/`null`, vazio, valores limite)?
- Caminhos de erro são tratados (não só o caminho feliz)?
- Passa em todos os testes? Os testes realmente testam as coisas certas?
- Há erros de off-by-one, condições de corrida (race conditions) ou inconsistências de estado?

### 2. Legibilidade e Simplicidade

Outro engenheiro (ou agente) consegue entender esse código sem o autor explicar?

- Os nomes são descritivos e consistentes com as convenções do projeto? (Nada de `temp`, `data`, `result` sem contexto)
- O fluxo de controle é direto (evite ternários aninhados, callbacks profundos)?
- O código está organizado logicamente (código relacionado agrupado, limites de módulo claros)?
- Há algum truque "esperto" que deveria ser simplificado?
- **Isso poderia ser feito em menos linhas?** (1000 linhas onde 100 bastam é uma falha)
- **As abstrações justificam sua complexidade?** (Não generalize antes do terceiro caso de uso)
- Comentários ajudariam a esclarecer uma intenção não óbvia? (Mas não comente código óbvio.)
- Há artefatos de código morto: variáveis sem uso real (`$_unused`, `_unused`), shims de compatibilidade retroativa, ou comentários tipo `// removido`?
- **Um novo condicional foi encaixado à força em um fluxo não relacionado?** Isso é um cheiro de design, não um nit — mova a lógica para seu próprio helper, estado ou política em vez de emaranhar um fluxo existente.
- **Aparecem condicionais repetidos sobre a mesma forma de dado?** Isso sinaliza um modelo ou dispatcher ausente. Uma branch "temporária" costuma ser dívida permanente.

### 3. Arquitetura

A mudança se encaixa no design do sistema?

- Segue os padrões existentes ou introduz um novo? Se novo, está justificado?
- Mantém limites de módulo (module boundaries) limpos?
- Há duplicação de código que deveria ser compartilhada?
- As dependências fluem na direção certa (sem dependências circulares)?
- O nível de abstração é apropriado (nem over-engineered, nem acoplado demais)?
- **Essa refatoração reduz a complexidade ou só a realoca?** Conte os conceitos que um leitor precisa manter na cabeça para acompanhar a mudança. Se a versão "mais limpa" mantém essa contagem igual, ela não é mais limpa — prefira a reestruturação que faz branches, modos ou camadas inteiras desaparecerem em vez de uma que apenas recentraliza a mesma lógica. Prefira apagar uma abstração a poli-la.
- **Lógica específica de uma funcionalidade está vazando para um módulo compartilhado ou de propósito geral?** Mantenha a lógica na camada dona do conceito, reutilize o helper canônico existente em vez de um quase-duplicado, e não normalize a deriva arquitetural.
- **Os limites de tipo estão explícitos?** Questione `any`/`unknown`/casts gratuitos em TypeScript, `mixed` sem necessidade e supressões de tipo em PHP (`@phpstan-ignore`, `@psalm-suppress`), ou o uso de `interface{}`/`any` em Go onde um tipo concreto bastaria — e desconfie de fallbacks silenciosos que escondem um invariante pouco claro. Tornar o limite explícito costuma simplificar o fluxo de controle ao redor.

### 4. Segurança

Para orientação detalhada de segurança, veja `security-and-hardening`. A mudança introduz vulnerabilidades?

- O input do usuário é validado e sanitizado?
- Segredos ficam fora do código, dos logs e do controle de versão?
- Autenticação/autorização são checadas onde necessário?
- Consultas SQL são parametrizadas (prepared statements — sem concatenação de string)?
- Saídas são escapadas/encodadas para prevenir XSS (relevante em views/templates PHP; menos comum em APIs Go que só retornam JSON, mas ainda vale para HTML renderizado no servidor)?
- As dependências vêm de fontes confiáveis e sem vulnerabilidades conhecidas?
- Dados de fontes externas (APIs, logs, conteúdo do usuário, arquivos de configuração) são tratados como não confiáveis?
- Os fluxos de dados externos são validados nos limites do sistema antes de entrar na lógica ou na renderização?

### 5. Performance

Para profiling e otimização detalhados, veja `performance-optimization`. A mudança introduz problemas de performance?

- Algum padrão N+1 de consulta (ex.: N+1 em um ORM como Eloquent/Doctrine em PHP, ou em um loop de queries em Go)?
- Loops sem limite ou busca de dados sem restrição (paginação/limite)?
- Alguma operação síncrona/bloqueante que deveria ser assíncrona ou concorrente (fila/job assíncrono em PHP, goroutine em Go)?
- Em Go: alguma goroutine vazando, ou uso de `sync.Mutex`/canal que serializa um caminho que deveria ser paralelo?
- Em PHP: algum trabalho pesado repetido a cada requisição que deveria ser cacheado (cache de aplicação, opcache, memoização)?
- Falta paginação em algum endpoint de listagem?
- Objetos grandes sendo criados em caminhos quentes (hot paths)?

## Remédios Estruturais

Ao apontar um problema estrutural, proponha a solução — não só o problema. Uma revisão que só diz "isso está complexo" deixa o autor sem rumo. Recorra a uma reestruturação com nome:

- **Substituir uma cadeia de condicionais** por um modelo tipado ou um dispatcher explícito.
- **Colapsar branches duplicadas** em um único fluxo mais claro.
- **Separar orquestração de lógica de negócio** para que cada uma se leia isoladamente.
- **Mover lógica específica de uma funcionalidade** para fora de um módulo compartilhado, para o pacote/namespace dono do conceito.
- **Reutilizar o helper canônico** em vez de um quase-duplicado feito sob medida.
- **Tornar um limite de tipo explícito** para que o branching downstream desapareça.
- **Apagar um wrapper de passagem** que adiciona indireção sem esclarecer a API.
- **Extrair um helper, ou dividir um arquivo grande** em módulos focados (classes menores em PHP, pacotes/arquivos menores em Go).

Prefira o remédio que remove peças móveis a um que apenas espalhe a mesma complexidade.

## Tamanho da Mudança

Mudanças pequenas e focadas são mais fáceis de revisar, mais rápidas de mesclar e mais seguras de fazer deploy. Tenha estes tamanhos como alvo:

```
~100 linhas alteradas   → Bom. Revisável de uma vez só.
~300 linhas alteradas   → Aceitável se for uma única mudança lógica.
~1000 linhas alteradas  → Grande demais. Divida.
```

**Observe o tamanho do arquivo, não só o tamanho do diff.** Um diff pequeno ainda pode empurrar um arquivo para além de um limite saudável — cerca de 1000 linhas *totais* em um único arquivo (diferente do limite de ~1000 linhas *alteradas* acima) é um sinal comum de inspeção, não um teto rígido. Quando uma mudança faz um arquivo já grande crescer de forma relevante, pergunte se vale extrair helpers, subcomponentes ou módulos *antes*, em vez de empilhar mais código em cima. Decomponha, depois adicione.

**O que conta como "uma mudança":** uma modificação única e autocontida que resolve uma coisa, inclui os testes relacionados, e mantém o sistema funcional após o envio. Uma parte de uma funcionalidade — não a funcionalidade inteira.

**Estratégias de divisão quando uma mudança é grande demais:**

| Estratégia | Como | Quando |
|----------|-----|------|
| **Empilhada (stack)** | Envie uma mudança pequena, comece a próxima em cima dela | Dependências sequenciais |
| **Por grupo de arquivos** | Mudanças separadas para grupos que precisam de revisores diferentes | Preocupações transversais |
| **Horizontal** | Crie código/stubs compartilhados primeiro, depois os consumidores | Arquitetura em camadas |
| **Vertical** | Divida em fatias menores full-stack da funcionalidade | Trabalho de feature |

**Quando mudanças grandes são aceitáveis:** exclusões completas de arquivo e refatoração automatizada, em que o revisor só precisa verificar a intenção, não cada linha.

**Separe refatoração de trabalho de funcionalidade.** Uma mudança que refatora código existente e adiciona comportamento novo é, na verdade, duas mudanças — envie-as separadamente. Pequenas limpezas (renomear variável) podem ser incluídas a critério do revisor.

## Descrições de Mudança

Toda mudança precisa de uma descrição que se sustente sozinha no histórico do controle de versão.

**Primeira linha:** curta, no imperativo, autossuficiente. "Remove o RPC do FizzBuzz" e não "Removendo o RPC do FizzBuzz". Precisa ser informativa o bastante para que alguém pesquisando o histórico entenda a mudança sem ler o diff.

**Corpo:** o que está mudando e por quê. Inclua contexto, decisões e raciocínio que não estão visíveis no próprio código. Linke números de bug, resultados de benchmark ou documentos de design quando relevante. Reconheça limitações da abordagem quando existirem.

**Antipadrões:** "Corrige bug", "Corrige build", "Adiciona patch", "Movendo código de A para B", "Fase 1", "Adiciona funções de conveniência".

## Processo de Revisão

### Passo 1: Entender o Contexto

Antes de olhar o código, entenda a intenção:

```
- O que essa mudança está tentando resolver?
- Qual especificação ou tarefa ela implementa?
- Qual é a mudança de comportamento esperada?
```

### Passo 2: Revise os Testes Primeiro

Testes revelam intenção e cobertura:

```
- Existem testes para a mudança?
- Eles testam comportamento (não detalhes de implementação)?
- Casos de borda estão cobertos?
- Os testes têm nomes descritivos?
- Os testes pegariam uma regressão se o código mudasse?
```

### Passo 3: Revise a Implementação

Percorra o código com os cinco eixos em mente:

```
Para cada arquivo alterado:
1. Correção: esse código faz o que o teste diz que deveria fazer?
2. Legibilidade: consigo entender sem ajuda?
3. Arquitetura: isso se encaixa no sistema?
4. Segurança: alguma vulnerabilidade?
5. Performance: algum gargalo?
```

### Passo 4: Categorize os Achados

Rotule cada comentário com sua severidade, para que o autor saiba o que é obrigatório e o que é opcional:

| Prefixo | Significado | Ação do Autor |
|--------|---------|---------------|
| *(sem prefixo)* | Mudança obrigatória | Precisa ser resolvida antes do merge |
| **Crítico:** | Bloqueia o merge | Vulnerabilidade de segurança, perda de dados, funcionalidade quebrada |
| **Nit:** | Menor, opcional | O autor pode ignorar — formatação, preferências de estilo |
| **Opcional:** / **Considere:** | Sugestão | Vale considerar, mas não é obrigatório |
| **FYI** | Apenas informativo | Nenhuma ação necessária — contexto para referência futura |

Isso evita que autores tratem todo feedback como obrigatório e percam tempo com sugestões opcionais.

**Comece pelo que importa.** Ordene os achados por alavancagem: correção e segurança primeiro, depois regressões estruturais e simplificações perdidas, depois o resto. Não enterre um problema real sob nits cosméticos — poucos comentários de alta convicção valem mais que uma lista longa. Se você tem um problema estrutural e dez nits, o problema estrutural *é* a revisão.

### Passo 5: Verifique a Verificação

Confira a história de verificação do autor:

```
- Quais testes foram rodados?
- O build passou?
- A mudança foi testada manualmente?
- Há screenshots para mudanças de UI?
- Há uma comparação antes/depois?
```

## Padrão de Revisão Multi-Modelo

Use modelos diferentes para perspectivas de revisão diferentes:

```
Modelo A escreve o código
    │
    ▼
Modelo B revisa correção e arquitetura
    │
    ▼
Modelo A responde ao feedback
    │
    ▼
Humano toma a decisão final
```

Isso pega problemas que um único modelo poderia deixar passar — modelos diferentes têm pontos cegos diferentes.

**Exemplo de prompt para um agente de revisão:**
```
Revise esta mudança de código quanto a correção, segurança e aderência
às nossas convenções de projeto. A especificação diz [X]. A mudança deveria [Y].
Marque qualquer problema como Crítico, Obrigatório, Opcional ou Nit.
```

## Higiene de Código Morto

Depois de qualquer refatoração ou mudança de implementação, verifique se sobrou código órfão:

1. Identifique código que agora é inalcançável ou não usado
2. Liste-o explicitamente
3. **Pergunte antes de apagar:** "Posso remover estes elementos agora sem uso: [lista]?"

Não deixe código morto por aí — isso confunde leitores e agentes futuros. Mas também não apague silenciosamente coisas de que você não tem certeza. Na dúvida, pergunte.

**PHP:**

```
CÓDIGO MORTO IDENTIFICADO:
- formatLegacyDate() em src/Support/DateHelper.php — substituída por formatDate()
- classe LegacyInvoicePdf em src/Billing/ — substituída por InvoicePdfGenerator
- constante LEGACY_API_URL em config/services.php — sem referências restantes
→ Posso remover esses itens?
```

**Go:**

```
CÓDIGO MORTO IDENTIFICADO:
- FormatLegacyDate() em internal/support/date.go — substituída por FormatDate()
- struct LegacyInvoiceBuilder em internal/billing/ — substituída por InvoiceBuilder
- constante LegacyAPIURL em internal/config/config.go — sem referências restantes
→ Posso remover esses itens?
```

## Velocidade de Revisão

Revisões lentas bloqueiam times inteiros. O custo de trocar de contexto para revisar é menor que o custo de espera imposto aos outros.

- **Responda dentro de um dia útil** — isso é o máximo, não a meta
- **Cadência ideal:** responda logo depois que o pedido de revisão chegar, a menos que esteja em foco profundo em outra coisa. Uma mudança típica deveria completar múltiplas rodadas de revisão no mesmo dia
- **Priorize respostas individuais rápidas** em vez de uma aprovação final rápida. Feedback rápido reduz frustração mesmo que sejam necessárias várias rodadas
- **Mudanças grandes:** peça ao autor para dividi-las em vez de revisar um changeset gigante de uma vez

## Lidando com Discordâncias

Ao resolver disputas de revisão, aplique esta hierarquia:

1. **Fatos técnicos e dados** têm prioridade sobre opiniões e preferências
2. **Guias de estilo** são a autoridade absoluta em questões de estilo
3. **Design de software** deve ser avaliado por princípios de engenharia, não preferência pessoal
4. **Consistência da base de código** é aceitável se não degradar a saúde geral

**Não aceite "eu limpo isso depois".** A experiência mostra que a limpeza adiada raramente acontece. Exija a limpeza antes do envio, a menos que seja uma emergência genuína. Se problemas ao redor não puderem ser resolvidos nesta mudança, exija a abertura de um bug com auto-atribuição.

## Honestidade na Revisão

Ao revisar código — seja escrito por você, por outro agente, ou por um humano:

- **Não carimbe aprovação sem critério.** "LGTM" sem evidência de revisão não ajuda ninguém.
- **Não suavize problemas reais.** "Isso pode ser uma preocupação menor" quando é um bug que vai atingir produção é desonesto.
- **Quantifique problemas quando possível.** "Essa consulta N+1 vai adicionar ~50ms por item na listagem" é melhor que "isso pode ficar lento".
- **Questione abordagens com problemas claros.** Bajulação (sycophancy) é um modo de falha em revisões. Se a implementação tem problemas, diga isso diretamente e proponha alternativas.
- **Aceite ser sobreposto com elegância.** Se o autor tem contexto completo e discorda, defira ao julgamento dele. Comente o código, não as pessoas — reformule críticas pessoais para focar no código em si.

## Disciplina de Dependências

Parte do code review é a revisão de dependências:

**Antes de adicionar qualquer dependência:**
1. A stack existente já resolve isso? (Muitas vezes resolve.)
2. Qual o tamanho da dependência? (Em PHP, veja o impacto no `vendor/`; em Go, no binário final e no `go.sum`.)
3. Ela é mantida ativamente? (Confira o último commit, issues abertas.)
4. Tem vulnerabilidades conhecidas? (`composer audit` em PHP; `govulncheck ./...` em Go)
5. Qual é a licença? (Precisa ser compatível com o projeto.)

**Regra:** prefira a biblioteca padrão e utilitários já existentes a novas dependências. Toda dependência é um passivo.

**Atualizar uma dependência existente** é uma mudança de código como qualquer outra, e as atualizações mais arriscadas são aquelas mescladas em bloco com uma mensagem do tipo "bump deps". Revise-as com a mesma disciplina:

1. **Leia o changelog, não só o número da versão.** Semver é uma promessa que o mantenedor pode não ter cumprido — um "patch" pode carregar uma mudança de comportamento. Para um bump de versão major, leia as notas de migração e descubra o que quebra.
2. **Uma dependência por mudança.** Atualize e mescle-as individualmente (ou em pequenos grupos relacionados). Quando um bump em bloco quebra o build, você perde a informação de qual pacote foi o causador; uma mudança de um único pacote deixa a causa óbvia e o revert limpo.
3. **Deixe os testes decidirem.** A atualização é verificada por uma suíte de testes verde antes *e* depois, não por "instalou sem erro". Se a cobertura em torno do comportamento da dependência for fraca, essa lacuna é o achado real — adicione um teste primeiro.
4. **Preste atenção ao grafo transitivo.** A maioria dos pacotes instalados são pacotes que ninguém escolheu diretamente. Revise o diff do lockfile (`composer.lock` em PHP; `go.sum`, junto com `go.mod`, em Go), não só o manifesto principal (`composer.json`/`go.mod`); um bump direto único pode arrastar dezenas de mudanças indiretas.
5. **Mantenha o lockfile íntegro.** Faça commit dele, revise seu diff, e nunca o edite manualmente. O lockfile é o que de fato fixa o que vai para produção.

Para triagem de achados do `composer audit`/`govulncheck` e risco de supply chain (typosquatting, mantenedores comprometidos), siga a skill `security-and-hardening` — esta seção cobre o *fluxo de trabalho* de atualização, aquela cobre o veredito de segurança.

## O Checklist de Revisão

```markdown
## Revisão: [Título do PR/Mudança]

### Contexto
- [ ] Entendo o que essa mudança faz e por quê

### Correção
- [ ] A mudança atende à especificação/aos requisitos da tarefa
- [ ] Casos de borda tratados
- [ ] Caminhos de erro tratados
- [ ] Testes cobrem a mudança adequadamente

### Legibilidade
- [ ] Nomes são claros e consistentes
- [ ] A lógica é direta
- [ ] Sem complexidade desnecessária

### Arquitetura
- [ ] Segue os padrões existentes
- [ ] Sem acoplamento ou dependências desnecessárias
- [ ] Nível de abstração apropriado
- [ ] Refatorações reduzem complexidade em vez de realocá-la
- [ ] Sem lógica de feature em módulos compartilhados; arquivo dentro de um tamanho saudável

### Segurança
- [ ] Sem segredos no código
- [ ] Input validado nos limites
- [ ] Sem vulnerabilidades de injeção
- [ ] Checagens de autenticação/autorização no lugar
- [ ] Fontes de dados externas tratadas como não confiáveis

### Performance
- [ ] Sem padrões N+1
- [ ] Sem operações sem limite
- [ ] Paginação nos endpoints de listagem

### Verificação
- [ ] Testes passam
- [ ] Build funciona
- [ ] Verificação manual feita (quando aplicável)

### Veredito
- [ ] **Aprovar** — pronto para merge
- [ ] **Solicitar mudanças** — problemas precisam ser resolvidos
```

## Veja Também

- Para orientação detalhada de revisão de segurança, veja `../../references/security-checklist.md`
- Para checagens de revisão de performance, veja `../../references/performance-checklist.md`

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Funciona, já é bom o suficiente" | Código que funciona mas é ilegível, inseguro ou arquiteturalmente errado gera dívida que se acumula. |
| "Eu escrevi, então sei que está correto" | Autores são cegos às próprias suposições. Toda mudança se beneficia de outro par de olhos. |
| "Depois a gente limpa isso" | Depois nunca chega. A revisão é o quality gate — use-a. Exija a limpeza antes do merge, não depois. |
| "Código gerado por IA provavelmente está ok" | Código de IA precisa de mais escrutínio, não menos. Ele é confiante e plausível mesmo quando está errado. |
| "Os testes passam, então está bom" | Testes são necessários, mas não suficientes. Eles não pegam problemas de arquitetura, questões de segurança ou de legibilidade. |
| "A refatoração deixa mais limpo" | Realocar complexidade não é reduzi-la. Se o leitor ainda precisa segurar o mesmo número de conceitos, a estrutura não melhorou — procure a versão em que as branches desaparecem. |
| "É só uma pequena adição a este arquivo" | Diffs pequenos ainda empurram arquivos além de um tamanho saudável e encaixam branches em fluxos não relacionados. Julgue a estrutura resultante, não o tamanho do diff. |
| "É só um bump de versão" | Um bump é uma mudança de comportamento que você não escreveu. Leia o changelog; semver não garante ausência de quebra. |
| "Vou atualizar tudo em um PR só para economizar tempo" | Um bump em bloco que quebra o build esconde qual pacote foi o causador. Uma dependência por mudança mantém a causa e o revert limpos. |

## Sinais de Alerta

- PRs mesclados sem nenhuma revisão
- Revisão que só checa se os testes passam (ignorando os outros eixos)
- "LGTM" sem evidência de revisão real
- Mudanças sensíveis à segurança sem revisão focada em segurança
- PRs grandes demais "para revisar direito" (divida-os)
- Sem testes de regressão em PRs de correção de bug
- Comentários de revisão sem rótulo de severidade — deixa incerto o que é obrigatório e o que é opcional
- Aceitar "eu conserto depois" — isso nunca acontece
- Uma refatoração que move código sem reduzir o número de conceitos que o leitor precisa manter na cabeça
- Uma mudança que faz um arquivo já grande crescer em vez de decompô-lo
- Novos condicionais espalhados em caminhos de código não relacionados (uma abstração ausente)
- Um helper sob medida que duplica um canônico já existente, ou lógica de feature colocada em um módulo compartilhado
- Um PR de "bump de dependências" em bloco sem revisão de changelog e sem isolamento por pacote
- Uma mudança de lockfile (`composer.lock`, `go.sum`) editada manualmente, não commitada, ou mesclada sem revisar seu diff

## Verificação

Depois que a revisão estiver completa:

- [ ] Todos os problemas Críticos estão resolvidos
- [ ] Todas as mudanças Obrigatórias (sem prefixo) estão resolvidas ou explicitamente adiadas com justificativa
- [ ] Os testes passam
- [ ] O build funciona
- [ ] A história de verificação está documentada (o que mudou, como foi verificado)
- [ ] Atualizações de dependência foram revisadas contra o changelog, isoladas por pacote, e verificadas por uma suíte de testes verde, com o diff do lockfile revisado

**Bloqueadores presumidos:** aponte e proponha o design mais simples para cada um destes; só escale para Obrigatório quando a mudança piorar ativamente a estrutura: uma refatoração que realoca complexidade em vez de reduzi-la; uma mudança que empurra um arquivo além do limite de tamanho sem decomposição; lógica de feature adicionada a um módulo compartilhado; um quase-duplicado de um helper canônico existente; um fallback silencioso que esconde um invariante pouco claro.
