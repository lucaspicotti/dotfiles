---
name: performance-optimization
description: "Otimiza performance nos projetos PHP 7.4 (Zend Framework 1, PSR-4, APIs, portal com JS vanilla/jQuery/Sass, crons) e Go (backend hexagonal, OCPP), com PostgreSQL. Use quando existirem requisitos de performance, quando houver suspeita de regressão, quando uma tela do portal, relatório, exportação, cron ou endpoint estiver lento, quando consultas N+1 ou sem índice precisarem de correção, quando memória ou goroutines crescerem, ou quando profiling (Zend_Db_Profiler, Xdebug, pprof, DevTools) revelar gargalos."
---

# Otimização de Performance

## Visão Geral

Meça antes de otimizar. Trabalho de performance sem medição é chute, e chute leva a otimização prematura, que adiciona complexidade sem melhorar o que importa. Faça o profiling primeiro, identifique o gargalo real, corrija-o e meça de novo. Otimize só o que a medição prova que importa.

Contexto das stacks:

- **PHP 7.4** (confirme no `composer.json` do projeto): PHP-FPM sem estado entre requisições, portal Zend Framework 1 com Smarty, APIs REST em `application/Api/`, código PSR-4 em `src/`, crons em `application/cron/`/`cli.php`, JS vanilla/jQuery em `public/scripts/`, Sass em `frontend/scss/` compilado para `public/styles/modern/`. PostgreSQL via `PDO_PGSQL`, com banco central e bancos de operador.
- **Go**: backend puro, hexagonal, conforme o `AGENTS.md` do projeto (ex.: `/var/www/GoOcppServer`). Conexões WebSocket OCPP de longa duração, uma goroutine por mensagem recebida, locks por chave (`keylock`), filas finitas. PostgreSQL é a direção planejada para persistência.

Leia o `AGENTS.md` do repositório antes de mexer: regras como "não bloqueie um handler OCPP esperando comando remoto" ou "use transações nas operações financeiras" são restrições de correção que nenhuma otimização pode violar.

## Quando Usar

- Existe requisito de performance na especificação (SLA de resposta, tempo de relatório, capacidade de carregadores conectados)
- Usuários ou monitoramento relatam lentidão (tela do portal, relatório, exportação, API do app, cron que atrasa)
- Um cron estoura memória ou tempo, ou o processo Go cresce em memória/goroutines
- Você suspeita que uma mudança introduziu regressão
- Você está construindo funcionalidades que lidam com muitos dados (relatórios, exportações, listagens de transações) ou muito tráfego (mensagens OCPP)

**Quando NÃO usar:** não otimize antes de ter evidência de um problema. Otimização prematura adiciona uma complexidade que custa mais do que a performance que ela ganha.

## Metas de Referência

Defina o orçamento com o time; na falta dele, use estes pontos de partida:

| Superfície | Métrica | Bom | Precisa melhorar | Ruim |
|---|---|---|---|---|
| Portal (tela) | **INP** (Interaction to Next Paint): cliques em tabelas, filtros, modais | ≤ 200ms | ≤ 500ms | > 500ms |
| Portal (tela) | **LCP** (Largest Contentful Paint) | ≤ 2,5s | ≤ 4,0s | > 4,0s |
| Portal (tela) | **CLS** (Cumulative Layout Shift) | ≤ 0,1 | ≤ 0,25 | > 0,25 |
| API PHP / Go | Latência p95 | ≤ 200ms | ≤ 500ms | > 500ms |
| OCPP (Go) | Tempo até responder uma mensagem do carregador (`Heartbeat`, `StatusNotification`) | Bem abaixo do timeout do carregador | — | Perto do timeout |
| Cron / relatório | Pico de memória e duração | Estável e proporcional ao volume | Cresce mais que o volume | Estoura `memory_limit`/janela |

O portal é uma aplicação administrativa interna com tabelas pesadas: **INP** (responsividade a cliques e filtros) costuma importar mais que LCP.

## O Fluxo de Otimização

```
1. MEDIR       → Estabeleça uma baseline com dados reais
2. IDENTIFICAR → Encontre o gargalo real (não o presumido)
3. CORRIGIR    → Ataque aquele gargalo específico
4. VERIFICAR   → Meça de novo; mantenha ou reverta
5. PROTEGER    → Adicione teste ou monitoramento contra regressão
```

### Passo 1: Medir

**Portal (frontend):** use o Chrome DevTools (aba Performance e Lighthouse) ou o Chrome DevTools MCP, seguindo a skill `browser-testing-with-devtools` (trace de performance, auditoria Lighthouse, requisições de rede). Para um portal interno, o trace sintético mais o relato do usuário geralmente bastam. Se precisar de dados de campo, carregue a lib `web-vitals` (build IIFE) em telas específicas.

**PHP (backend):**

```php
// Tempo e memória de um trecho (log estruturado, não echo)
$inicio = microtime(true);
$resultado = $this->relatorioService->gerar($filtro);
$this->logger->info('relatorio.gerado', [
    'duracao_ms' => (int) ((microtime(true) - $inicio) * 1000),
    'pico_memoria_mb' => (int) (memory_get_peak_usage(true) / 1048576),
]);

// Quantas queries e quanto tempo de banco (Zend_Db_Profiler; só em dev/teste)
$db->getProfiler()->setEnabled(true);
// ... executa o fluxo ...
$profiler = $db->getProfiler();
$this->logger->info('db.perfil', [
    'queries' => $profiler->getTotalNumQueries(),
    'segundos' => $profiler->getTotalElapsedSecs(),
]);
```

- **Xdebug profiler** (somente em dev) + KCachegrind/QCachegrind para CPU por função. Nunca ligue Xdebug em produção.
- **PostgreSQL:** `EXPLAIN (ANALYZE, BUFFERS)` da query, `pg_stat_statements` para as queries mais caras, `log_min_duration_statement` para queries lentas.

**Go:**

```bash
# Benchmark com alocações, repetido para medir a variância
go test ./internal/application/startcharge/ -run '^$' -bench . -benchmem -count=10 > antes.txt

# Perfis de CPU e memória do benchmark
go test ./internal/application/startcharge/ -run '^$' -bench . -cpuprofile cpu.out -memprofile mem.out
go tool pprof -top cpu.out

# Contenção de lock e bloqueio (ative SetMutexProfileFraction/SetBlockProfileRate no teste ou processo)
go test ./internal/adapters/ocpp16/ -run '^$' -bench . -mutexprofile mutex.out -blockprofile block.out
```

```go
// Benchmark (Go 1.24+: b.Loop evita que o setup entre na medição)
func BenchmarkAuthorizeSameConnector(b *testing.B) {
	uc := newAuthorizeForBenchmark(b) // ilustrativo: fakes nomeadas, sem rede
	ctx := b.Context()
	for b.Loop() {
		if _, err := uc.Execute(ctx, sampleRequest); err != nil {
			b.Fatal(err)
		}
	}
}
```

Não meça performance com `-race`: o detector deixa o código de 2 a 20 vezes mais lento e distorce o perfil.

### Por Onde Começar a Medir

Use o sintoma para decidir o que medir primeiro:

```
O que está lento?
├── Tela do portal abre devagar
│   ├── TTFB alto (Network do DevTools)? --> O PHP está lento: Zend_Db_Profiler, EXPLAIN, Xdebug
│   ├── Muitos/grandes CSS/JS/fontes? --> Waterfall de rede, tamanho dos assets, cache
│   └── Tabela enorme renderizada de uma vez? --> Paginação no servidor
├── Tela trava ao interagir (clique, filtro, digitação)
│   ├── Long tasks > 50ms no trace? --> JS montando DOM em loop, handlers pesados
│   ├── Filtro dispara uma requisição por tecla? --> Debounce + abort da requisição anterior
│   └── Jank ao rolar/animar? --> Layout thrashing (ler/escrever layout em loop)
├── Relatório / exportação
│   ├── Muitas queries? --> N+1 (conte com Zend_Db_Profiler)
│   ├── Uma query lenta? --> EXPLAIN (ANALYZE, BUFFERS), índices, predicado com função
│   └── Memória explode? --> fetchAll de tudo; use cursor/keyset e escrita em streaming
├── Cron lento ou estourando memória
│   └── Mesmos itens do relatório + trabalho repetido por item (chamadas HTTP em loop)
├── API PHP lenta
│   ├── Um endpoint? --> Queries e chamadas externas desse fluxo
│   ├── Todos? --> Workers do PHP-FPM ocupados, conexões no PostgreSQL, OPcache desligado
│   └── Intermitente? --> Locks no banco, gateway/ERP externo lento, cron concorrente
└── Go
    ├── Latência de resposta OCPP? --> Handler bloqueado, contenção em keylock (mutex profile)
    ├── CPU alta? --> pprof CPU
    ├── Memória crescendo? --> pprof heap (inuse_space), mapas/caches sem limite
    └── Goroutines crescendo? --> pprof goroutine; goroutine sem owner/cancelamento
```

### Passo 2: Identificar o Gargalo

Gargalos comuns por categoria:

**Portal (frontend):**

| Sintoma | Causa provável | Investigação |
|---|---|---|
| INP ruim em tabelas | Montagem de DOM item a item, um handler por linha, plugins de tabela no cliente com milhares de linhas | Long tasks no trace de Performance |
| Filtro/autocomplete lento | Uma requisição por tecla, respostas fora de ordem | Aba Network durante a digitação |
| LCP lento | TTFB do PHP, CSS/JS bloqueantes no `<head>`, fontes grandes | Waterfall de rede |
| CLS alto | Imagens sem dimensões, conteúdo inserido via AJAX acima do conteúdo, troca de fonte | Atribuição de layout shift |

**PHP (backend):**

| Sintoma | Causa provável | Investigação |
|---|---|---|
| Endpoint/tela lenta | N+1, falta de índice, predicado não indexável, chamada HTTP síncrona | Zend_Db_Profiler, EXPLAIN, timing em volta das chamadas externas |
| `Allowed memory size exhausted` | `fetchAll`/`toArray` de tabela inteira, PHPExcel com planilha grande | `memory_get_peak_usage`, tamanho do resultado |
| Tudo lento ao mesmo tempo | Workers do PHP-FPM esgotados, `max_connections` do PostgreSQL, OPcache desligado | Status do FPM, `pg_stat_activity`, `opcache_get_status()` |
| CPU alta | Loops com regex/`array_search` em arrays grandes, serialização repetida | Xdebug profiler |

**Go (backend):**

| Sintoma | Causa provável | Investigação |
|---|---|---|
| Latência alta | Lock segurado durante I/O, handler bloqueado esperando comando remoto | Mutex/block profile, trace |
| Memória crescendo | Mapas/caches sem limite, referências retidas, fila crescendo | Heap profile (`inuse_space`) comparado ao longo do tempo |
| Goroutines crescendo | Goroutine sem cancelamento, canal sem leitor | Perfil `goroutine` |
| CPU alta | Alocação em hot path, JSON/reflexão repetidos, regex compilada a cada chamada | CPU profile, `-benchmem` |

### Passo 3: Corrigir Anti-Padrões Comuns

#### Consultas N+1 (PHP / Zend)

```php
// RUIM: N+1, uma query por venda para buscar o terminal
$vendas = $this->vendaModel->fetchAll($select);
foreach ($vendas as $venda) {
    $venda->terminal = $this->terminalModel->find($venda->id_terminal)->current();
}

// BOM: uma query com JOIN
$select = $db->select()
    ->from(['v' => 'venda'], ['id', 'valor_centavos', 'data_venda'])
    ->join(['t' => 'terminal'], 't.id = v.id_terminal', ['terminal_serial' => 't.serial'])
    ->where('v.id_operador = ?', $idOperador);

// BOM: quando o JOIN não serve, uma query em lote com IN e um mapa por ID
$ids = array_unique(array_column($vendas, 'id_terminal'));
$terminais = $db->fetchAssoc(
    $db->select()->from('terminal', ['id', 'serial'])->where('id IN (?)', $ids)
);
```

`findDependentRowset`/`findParentRow` do `Zend_Db_Table_Row` dentro de loop é N+1 disfarçado. Em Go, o equivalente é uma query por item dentro de `for`: troque por `WHERE id = ANY($1)`.

#### Busca de Dados Sem Limite

```php
// RUIM: todas as linhas para a memória do PHP
$linhas = $db->fetchAll($select);

// BOM: paginado para telas e APIs
$select->order('v.data_venda DESC')->limitPage($pagina, 50);

// BOM: keyset para varrer tabelas grandes (OFFSET alto também custa caro)
$select->where('v.id > ?', $ultimoId)->order('v.id')->limit(1000);
```

**Exportações e crons:** o `pdo_pgsql` do PHP 7.4 traz o resultado inteiro para a memória, mesmo usando `fetch()` em loop. Para volumes grandes, use um cursor no servidor, ou keyset em lotes, e escreva em streaming (OpenSpout grava linha a linha; PHPExcel mantém a planilha toda em memória):

```php
$db->beginTransaction();
$db->query('DECLARE cursor_exportacao NO SCROLL CURSOR FOR ' . $select->assemble());
while ($lote = $db->fetchAll('FETCH 1000 FROM cursor_exportacao')) {
    foreach ($lote as $linha) {
        $writer->addRow(Row::fromValues($this->linhaDaPlanilha($linha))); // ilustrativo
    }
}
$db->query('CLOSE cursor_exportacao');
$db->commit();
```

#### Queries Que Ignoram o Índice

"Adiciona um índice" é o chute. O plano de execução é a medição:

```sql
-- Em escrita (UPDATE/DELETE), EXPLAIN ANALYZE EXECUTA a query: envolva em transação e desfaça
BEGIN;
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, valor_centavos FROM venda
WHERE id_operador = 42 AND data_venda >= '2026-09-01' AND data_venda < '2026-10-01'
ORDER BY data_venda DESC LIMIT 50;
ROLLBACK;
```

Rode em banco local ou de teste com volume representativo. Nunca rode em produção sem autorização.

Três coisas na saída decidem a correção:

| O que você vê | O que significa |
|---|---|
| `Seq Scan` numa tabela grande onde você esperava um índice | Não há índice utilizável para esse predicado |
| `rows=` estimado muito diferente do real (uma ordem de grandeza) | Estatísticas desatualizadas (`ANALYZE tabela`); o planner decide com informação ruim |
| Um nó `Sort` acima do scan | O índice cobre o filtro, mas não o `ORDER BY` |

Indexe pelo **formato da query**, não pela coluna isolada. Num índice composto, colunas de igualdade vêm primeiro, depois a de range ou ordenação:

```sql
CREATE INDEX CONCURRENTLY idx_venda_operador_data ON venda (id_operador, data_venda DESC);
```

Em tabela grande de produção, `CONCURRENTLY` evita travar escritas, mas não roda dentro de transação. Mudança de schema passa pelo mecanismo de publicação/migração do projeto e exige aprovação.

**Quando um índice não ajuda:**

| Situação | Por quê / o que fazer |
|---|---|
| Função na coluna: `WHERE date(data_venda) = ?`, `WHERE lower(email) = ?`, `to_char(...)` | O índice da coluna fica inutilizável. Reescreva como range (`data_venda >= ? AND data_venda < ?`) ou crie um índice de expressão |
| Curinga no início (`LIKE '%termo%'`, `ILIKE`) | B-tree não busca sem prefixo; precisa de `pg_trgm` (GIN) ou full-text |
| Baixa seletividade no valor dominante (`status` 95% `aprovada`, filtrando `aprovada`) | Seq scan é genuinamente mais barato. Para o valor raro, um índice parcial (`WHERE status = 'pendente'`) serve bem |
| Tipos diferentes na comparação (coluna `varchar` comparada a número, cast implícito) | O cast impede o uso do índice; compare com o tipo da coluna |
| Tabela com muita escrita (transações, medições) | Cada índice é um imposto em todo `INSERT`/`UPDATE`: meça o custo de escrita, não só o ganho de leitura |

Rode `EXPLAIN` de novo depois. Um índice que não mudou o plano é revertido (Passo 4), e ele não é de graça: continua custando em toda escrita.

#### Conexões com o Banco

**PHP-FPM não tem pool em processo.** Cada worker abre suas conexões por requisição, e um fluxo que toca o banco central e o do operador abre **duas**. O teto é aproximadamente `pm.max_children × servidores × conexões por requisição + crons`, que precisa ficar abaixo do `max_connections` do PostgreSQL. A assinatura do esgotamento: **todos** os endpoints ficam lentos ao mesmo tempo, o tempo é gasto esperando conexão ou worker livre, e o banco mostra muitas sessões ociosas.

- Não aumente `pm.max_children` para "resolver lentidão": se o gargalo é o banco, você só muda a fila de lugar.
- `PDO::ATTR_PERSISTENT` mantém conexões ociosas por worker e pode vazar estado (transação aberta, `SET` de sessão) entre requisições: só com medição e revisão.
- Para muitos servidores, a correção é um pooler (pgbouncer), não um `max_connections` maior.

**Go (`database/sql`/pgx, quando existir persistência):** um pool por processo, dimensionado contra o banco.

```go
db.SetMaxOpenConns(10)                  // instâncias × 10 precisa caber em max_connections
db.SetMaxIdleConns(10)
db.SetConnMaxLifetime(30 * time.Minute)
db.SetConnMaxIdleTime(5 * time.Minute)
// Toda query com ctx de timeout; todo rows.Close(); toda tx com Commit ou Rollback.
// Um rows sem Close segura a conexão: é a causa mais comum de "pool esgotado" em Go.
```

**Pool maior não é mais rápido.** Um pool maior do que o banco consegue executar em paralelo só realoca a fila do app para o banco, onde é mais difícil de ver. Descubra o que segura as conexões (transação longa, `rows` sem `Close`, chamada HTTP dentro de transação).

#### Trabalho Pesado Dentro da Requisição

- **PHP:** geração de relatório grande, envio de e-mail em massa ou chamada a vários serviços externos dentro da action seguram um worker do FPM pelo tempo todo. Mova para um cron ou fila existente e devolva o status. Chamadas externas com `connect_timeout` e `timeout` explícitos no Guzzle: um gateway lento não pode prender workers indefinidamente.
- **Go:** nunca bloqueie o handler OCPP esperando comando remoto (regra do `AGENTS.md`). Trabalho disparado por mensagem roda em goroutine com owner, cancelamento e espera no shutdown. Não segure lock (`keylock`, `sync.Mutex`) durante I/O de rede ou banco.

#### OPcache e Autoload (PHP)

- OPcache ligado em produção (`opcache.enable=1`). Com `opcache.validate_timestamps=0`, o deploy precisa resetar o cache (reload do FPM).
- Autoload do Composer otimizado em produção: `composer install --no-dev --optimize-autoloader` gera classmap para o PSR-4 de `src/`.
- O autoloader do Zend 1 via `include_path` percorre diretórios: mantenha o `include_path` curto e com as pastas mais usadas primeiro.

#### Portal: JS Vanilla / jQuery

```js
// RUIM: um reflow por item e um handler por linha
$.each(itens, function (_, item) {
    $('#tabela tbody').append('<tr><td>' + item.nome + '</td><td><button class="editar">…</button></td></tr>');
    $('#tabela .editar').last().on('click', function () { editar(item.id); });
});

// BOM: monta fora do DOM, insere uma vez, e usa delegação de eventos
var fragmento = document.createDocumentFragment();
itens.forEach(function (item) {
    var tr = document.createElement('tr');
    tr.dataset.id = item.id;
    var td = document.createElement('td');
    td.textContent = item.nome; // também evita XSS
    tr.appendChild(td);
    fragmento.appendChild(tr);
});
$('#tabela tbody').empty().append(fragmento);
$('#tabela').on('click', 'tr', function () { editar(this.dataset.id); }); // uma vez, na inicialização
```

```js
// Filtro/autocomplete: debounce e cancelamento da requisição anterior
var requisicaoFiltro = null;
var temporizador = null;
$('#busca').on('input', function () {
    var termo = this.value;
    clearTimeout(temporizador);
    temporizador = setTimeout(function () {
        if (requisicaoFiltro) { requisicaoFiltro.abort(); }
        requisicaoFiltro = $.getJSON('/clientes/buscar', { termo: termo }, renderizarResultados);
    }, 300);
});
```

- **Layout thrashing:** não alterne leitura (`.width()`, `.offset()`, `.outerHeight()`) e escrita (`.css()`) dentro de loops. Leia tudo primeiro, depois escreva tudo.
- **Tabelas grandes:** pagine no servidor (ex.: `src/Http/Paginacao` quando existir). Plugins de tabela no cliente com milhares de linhas destroem o INP.
- **Scripts:** no fim do `<body>` ou com `defer`; nada bloqueante no `<head>` além do necessário.
- **Cache de assets:** versione a URL (ex.: o parâmetro de versão que o layout já usa para JS/CSS, como `vsJsCss`) e sirva `public/scripts` e `public/styles` com `Cache-Control` longo. Sem versionamento, um cache longo entrega arquivo velho.

#### Portal: Sass, Fontes e Imagens

- Compile com saída comprimida em produção (`sass --style=compressed`) e sem source map público.
- Cada entry em `frontend/scss/entries/` gera um CSS independente: uma tela que carrega várias entries recebe cópias duplicadas dos componentes em comum. Uma entry por tela e componentes via `@use`.
- Fontes de ícone (`material-symbols`, `material-icons`) são arquivos grandes: carregue só o estilo/peso usado, em WOFF2, com `font-display: swap` (ou `block` em fontes de ícone, para não piscar o nome do ícone).
- Imagens com `width`/`height` explícitos (evita CLS), `loading="lazy"` abaixo da dobra e formato moderno (WebP) quando o suporte do público permitir.

#### Go: Alocação, Concorrência e Memória

```go
// RUIM: cresce e realoca o slice a cada append; regex compilada a cada chamada
var out []Session
for _, s := range all {
	if regexp.MustCompile(`^CP-\d+$`).MatchString(s.ChargePointID) {
		out = append(out, s)
	}
}

// BOM: regex compilada uma vez no pacote; capacidade reservada
var chargePointIDPattern = regexp.MustCompile(`^CP-\d+$`)

out := make([]Session, 0, len(all))
for _, s := range all {
	if chargePointIDPattern.MatchString(s.ChargePointID) {
		out = append(out, s)
	}
}
```

- **Contenção:** locks por chave (`keylock` por `ChargePointID` ou estação+conector) só serializam o necessário; não os troque por um mutex global. Nunca segure lock durante I/O.
- **Goroutines:** toda goroutine tem owner, cancelamento via `context` e espera no shutdown (regra do `AGENTS.md`). Filas e canais são finitos: fila cheia é erro explícito, não bloqueio infinito.
- **Memória:** mapas indexados por carregador/sessão precisam de remoção explícita quando a entidade sai. `GOMEMLIMIT` limita o heap em container, mas não corrige vazamento.
- **`sync.Pool`, caches de objeto e micro-otimizações** só com benchmark mostrando ganho acima do ruído.
- **pprof em produção** só em porta interna/autenticada, nunca no listener público (veja a skill `security-and-hardening`).

#### Cache Ausente

Faça cache do que é caro de produzir e lido muito mais vezes do que muda. Cachear uma query que já era rápida adiciona um salto, um bug de dado velho e uma política de expiração para manter, em troca de nada.

**Escolha a camada deliberadamente:**

| Camada | Visível para | Use quando | Custo |
|---|---|---|---|
| Memória da requisição (PHP: propriedade/variável estática; Go: variável local) | Uma requisição | O mesmo dado é buscado várias vezes no mesmo fluxo | Nenhum além de memória; morre com a requisição |
| APCu (PHP) / mapa em memória (Go) | Um servidor / uma instância | Dado pequeno, quente, e divergência entre servidores é aceitável | Cada servidor diverge; invalidar atinge só um |
| `Zend_Cache` com backend `File` (PHP) | Um servidor (disco local) | Resultado caro (relatório, lookup pesado) com TTL aceitável | Disco, limpeza de arquivos, divergência entre servidores |
| Compartilhado (Redis/Memcached, se existir na infra; tabela de cache no PostgreSQL) | Todos | Servidores/instâncias precisam concordar | Salto de rede e mais um serviço para operar |
| HTTP (`Cache-Control` nos assets versionados) | Navegador/proxy | Arquivos estáticos em `public/` | Invalidação depende do versionamento da URL |

```php
// Zend_Cache: a chave inclui TUDO de que a resposta depende
$chave = sprintf('resumo_terminais_op%d_niv%d_%s', $idOperador, $nivelUsuario, $dataRef->format('Ymd'));
$resumo = $this->cache->load($chave);
if ($resumo === false) {
    $resumo = $this->resumoService->calcular($idOperador, $dataRef);
    $this->cache->save($resumo, $chave, [], 300); // 5 min de dado velho aceitável: documente
}
```

**O design da chave decide a correção.** Toda entrada que muda a resposta entra na chave: operador/cliente, banco (central ou do operador), nível/permissões, usuário, idioma. Uma chave sem o operador é como os dados de um operador aparecem para outro, e isso chega em produção com cara de ganho de performance.

**Escolha uma estratégia de invalidação, não três:**

| Estratégia | Trade-off |
|---|---|
| TTL | A mais simples. Você aceita dado velho até o TTL: declare a janela aceitável explicitamente |
| Por evento/tag (`Zend_Cache` suporta tags no backend `File`) | Fresco na escrita, mas quem escreve precisa conhecer a topologia do cache |
| Chaves versionadas (`resumo:op42:v7`) | Nunca invalida, só para de ler chaves antigas. Custa memória/disco até a expiração |

**Proteja contra o stampede.** Uma chave quente expira, todas as requisições concorrentes erram juntas e a origem recebe a carga inteira de uma vez: é assim que um cache vira uma queda em vez de preveni-la. No PHP, sirva o valor velho enquanto uma única requisição recalcula (lock por `flock` ou advisory lock do PostgreSQL). No Go, coalesça misses concorrentes atrás de uma única chamada em andamento (veja `../../references/performance-checklist.md`).

**Não faça cache de:** nada cujo dado velho seja um bug de correção. Exemplos: saldo, status de transação/pré-autorização, permissões e ACL, estado de sessão de recarga, disponibilidade de conector. Também não faça cache de dado por usuário sob uma chave que não identifica o usuário. Veja `../../references/performance-checklist.md` para coalescing, padrões de escrita, cache negativo e o checklist de cache.

### Passo 4: Verificar (Manter ou Reverter)

Uma correção é uma hipótese até você medir de novo. Este passo decide se ela sobrevive.

**Meça de novo do mesmo jeito que mediu a baseline:** mesmo comando, mesmas condições, mesmo orçamento fixo (tempo, número de amostras ou de requisições). Uma baseline tirada com cache frio (OPcache, `Zend_Cache`, buffers do PostgreSQL) contra um resultado com cache quente mede o cache, não a sua mudança.

**Mude uma coisa por vez.** Três otimizações entregues juntas produzem um número só, e você não consegue atribuí-lo. Se precisarem ir juntas, meça cada uma isoladamente antes.

**Vença o ruído, não só a média.** Repita a medição e compare o delta com a variância entre execuções. Um ganho de 3% dentro de ±5% de variância não é ganho, é outra amostra.

- **Go:** `go test -bench ... -count=10` antes e depois, e compare com `benchstat antes.txt depois.txt` (`go run golang.org/x/perf/cmd/benchstat@latest`). Ele mostra a variância e se a diferença é estatisticamente significativa (`~` quer dizer "sem diferença").
- **PHP:** repita a requisição N vezes e compare a mediana (e o p95), não uma execução. Exemplo: `for i in $(seq 20); do curl -s -o /dev/null -w '%{time_total}\n' "$URL"; done | sort -n`. Para queries, compare `EXPLAIN (ANALYZE, BUFFERS)` e o número de queries do Zend_Db_Profiler.

Depois decida, estritamente:

| Resultado vs. baseline | Ação |
|---|---|
| Além do limite, testes verdes | **Mantenha.** Faça commit com os números de antes e depois na mensagem. |
| Dentro do ruído (sem mudança mensurável) | **Reverta.** |
| Pior | **Reverta.** |
| Melhorou, mas um teste ficou vermelho | **Reverta.** É uma regressão vestida de vitória. |

**"Neutro" é reverter, não manter.** Este é o passo que os times pulam: a mudança já foi escrita, jogá-la fora parece desperdício, então ela entra sem medição e a base acumula complexidade que nunca rendeu nada. O código que você mantém, você mantém para sempre. Faça-o se pagar.

**A correção vem antes da métrica.** A suíte fica verde (`composer test` / `make ci`) *e* o número se move. Uma "otimização" que ganha removendo trabalho de que o produto precisava é uma regressão, não uma vitória. Exemplos: pular uma validação, cachear algo que precisa ser fresco, tirar uma transação de um fluxo financeiro, soltar um lock que protegia uma sessão de recarga.

#### Registre toda tentativa, inclusive as revertidas

Trabalho revertido não deixa rastro no histórico do git, e é exatamente por isso que a mesma ideia morta é tentada de novo no trimestre seguinte. Mantenha um registro curto para que uma ideia descartada continue descartada:

| Ideia | Baseline → Resultado | Veredito | Por quê |
|---|---|---|---|
| Cache do resumo de terminais por 5 min | p95 1,8s → 1,7s | revertido | Dentro do ruído (±0,2s). O gargalo era um `date(data_venda)` sem índice. |
| Reescrever filtro de data como range + índice composto | p95 1,8s → 0,3s | mantido | `Seq Scan` virou `Index Scan` no plano. |
| Delegação de eventos na tabela de vendas | INP 420ms → 140ms | mantido | Long tasks sumiram do trace. |

Uma seção na descrição do PR ou um `PERF.md` no repositório servem. O que importa é que a próxima pessoa (ou o próximo agente) leia antes de propor um experimento e não repita um que já falhou.

### Passo 5: Proteger Contra Regressão

Proteja a métrica que o usuário sente, não todo número disponível: a mesma latência p95, INP, duração de cron ou número de queries que justificou a correção.

- **N+1 (PHP):** um teste de integração (`tests/Integration/`, estendendo `IntegrationTestCase`) que liga o `Zend_Db_Profiler`, executa o fluxo com N registros sintéticos e afirma que o número de queries não cresce com N.
- **Plano de query:** para a query crítica, um teste de integração pode rodar `EXPLAIN (FORMAT JSON)` e afirmar que não há `Seq Scan` na tabela grande. Use com parcimônia: depende de estatísticas e volume.
- **Go:** mantenha o benchmark ao lado do código (`*_test.go`) e compare com `benchstat` em mudanças no caminho quente. Adicionar benchmark ao CI ou mudar o `Makefile`/CI exige autorização (regra do `AGENTS.md`).
- **Portal:** trace/Lighthouse da tela antes e depois via skill `browser-testing-with-devtools`, com os números no PR.
- **Produção:** log estruturado de duração em fluxos críticos (relatórios, crons, endpoints do app) permite alertar em mudança de p95/p75. Se esse log não existir, proponha, mas não o invente em escopo alheio à tarefa.

Quando um guard disparar, volte ao Passo 1 e estabeleça uma baseline nova antes de propor outra correção.

**Orçamentos de partida (ajuste com o time):**

```
API PHP / Go:            p95 < 200ms
Tela do portal:          INP < 200ms; TTFB < 800ms
Relatório/exportação:    memória de pico constante em relação ao volume (streaming)
Cron:                    termina bem antes da próxima execução agendada
OCPP:                    resposta a mensagem do carregador sem esperar comando remoto
CSS por tela:            < 50KB gzip; JS próprio por tela: < 100KB gzip
```

## Veja Também

Para checklists detalhados, comandos de medição e a tabela de anti-padrões, veja `../../references/performance-checklist.md`.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "A gente otimiza depois" | Dívida de performance se acumula. Corrija anti-padrões óbvios (N+1, sem paginação) agora; adie micro-otimizações. |
| "No meu ambiente está rápido" | Seu banco local tem mil linhas; o do operador tem milhões. Meça com volume representativo. |
| "Essa otimização é óbvia" | Se você não mediu, você não sabe. Faça o profiling primeiro. |
| "É sistema interno, ninguém liga para 300ms" | O operador usa o portal o dia inteiro; cada clique lento em tabela custa horas de trabalho somadas. |
| "O framework cuida de performance" | Zend e `database/sql` não impedem N+1, `date(coluna)` na cláusula WHERE nem `fetchAll` de tabela inteira. |
| "A query está lenta, cria um índice" | Leia o plano antes. O índice pode já existir e estar inutilizável por uma função na coluna, e todo índice cobra nas escritas para sempre. |
| "Só coloca cache" | Cachear uma chamada barata não rende nada e adiciona bug de dado velho. Cache é para o que é caro *e* relido muito mais do que escrito. |
| "Aumenta o `pm.max_children` / o pool" | Se o gargalo é o banco, mais workers só movem a fila para o PostgreSQL. Descubra o que segura as conexões. |
| "Não ajudou muito, mas também não atrapalha" | Mudança neutra é revertida. Você paga manutenção para sempre e não ganhou nada. |
| "Já escrevemos, vamos manter" | Custo afundado. A medição não se importa com quanto tempo a mudança levou. |
| "A melhoria é óbvia, não precisa medir de novo" | Então medir de novo é barato e prova. Vitórias não medidas são como a complexidade neutra entra. |

## Sinais de Alerta

- Otimização sem dados de profiling que a justifiquem
- `find()`, `fetchRow()`, `findParentRow()` ou query dentro de `foreach`/`for`
- `fetchAll()` sem `LIMIT` em tela, API ou exportação
- `WHERE date(coluna) = ?`, `lower(coluna)`, `to_char(coluna)` ou `LIKE '%...'` em tabela grande sem índice adequado
- Índice adicionado sem plano de execução antes e depois que o justifique
- Chave de cache que omite uma entrada da qual a resposta depende (operador, banco, nível, usuário)
- Cache sem janela de dado velho declarada e sem estratégia de invalidação
- Cache de saldo, status de transação, permissões ou estado de sessão de recarga
- `pm.max_children` ou tamanho de pool aumentado em resposta a esgotamento, sem descobrir o que segura as conexões
- Chamada HTTP externa sem timeout, ou dentro de transação de banco
- Lock (`keylock`, `sync.Mutex`) segurado durante I/O; handler OCPP bloqueado esperando comando remoto
- Goroutine sem owner/cancelamento; mapa indexado por carregador sem remoção
- `.append()` dentro de loop, um handler por linha de tabela, requisição AJAX por tecla sem debounce
- Assets sem versionamento na URL servidos com cache longo, ou sem cache nenhum
- Benchmark rodado com `-race`, ou uma execução única comparada a outra execução única
- Otimizações mantidas sem uma nova medição que as justifique
- Várias otimizações agrupadas numa só medição, de modo que nenhuma mudança pode ser atribuída
- Uma "vitória" que exigiu alterar, pular ou apagar um teste
- A mesma otimização fracassada tentada mais de uma vez porque ninguém registrou a primeira tentativa

## Verificação

Depois de qualquer mudança relacionada a performance:

- [ ] Existem medições de antes e depois (números específicos)
- [ ] O resultado foi medido de novo do mesmo jeito que a baseline (mesmo comando, mesmas condições, cache no mesmo estado)
- [ ] A melhoria supera a variância entre execuções (`benchstat` / mediana de N repetições), não só a média
- [ ] Mudanças que não bateram a baseline foram revertidas, não mantidas como neutras
- [ ] As tentativas estão registradas, mantidas e revertidas, para que uma ideia morta não seja repetida
- [ ] O gargalo específico foi identificado e atacado
- [ ] Nenhuma query N+1 no código novo de busca de dados (número de queries não cresce com N)
- [ ] Todo novo índice é justificado por um plano de execução antes e depois, e seu custo de escrita foi considerado
- [ ] Todo novo cache declara o que compõe a chave (incluindo operador/usuário) e como fica velho
- [ ] Chamadas externas têm timeout; nenhuma fica dentro de transação
- [ ] Concorrência Go: sem lock durante I/O, goroutines com owner e cancelamento, `make race` verde
- [ ] A métrica medida tem um teste, benchmark ou log que detecta regressão
- [ ] Os testes existentes continuam passando (`composer test` / `make ci`): a otimização não quebrou comportamento
