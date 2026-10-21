# Checklist de Performance

Checklist de referência rápida para os projetos PHP 7.4 (Zend Framework 1, PSR-4, portal com JS vanilla/jQuery/Sass, crons) e Go (backend hexagonal, OCPP), com PostgreSQL. Use junto com a skill `performance-optimization` e com o eixo de performance da `code-review-and-quality`.

## Sumário

- [Metas de Referência](#metas-de-referência)
- [Diagnóstico de TTFB](#diagnóstico-de-ttfb)
- [Checklist do Portal (Frontend)](#checklist-do-portal-frontend)
- [Checklist de Backend PHP](#checklist-de-backend-php)
- [Checklist de PostgreSQL](#checklist-de-postgresql)
- [Checklist de Backend Go](#checklist-de-backend-go)
- [Estratégias de Cache](#estratégias-de-cache)
- [Comandos de Medição](#comandos-de-medição)
- [Anti-Padrões Comuns](#anti-padrões-comuns)

## Metas de Referência

| Métrica | Bom | Precisa melhorar | Ruim |
|--------|------|------------|------|
| INP (Interaction to Next Paint), telas do portal | ≤ 200ms | ≤ 500ms | > 500ms |
| LCP (Largest Contentful Paint) | ≤ 2,5s | ≤ 4,0s | > 4,0s |
| CLS (Cumulative Layout Shift) | ≤ 0,1 | ≤ 0,25 | > 0,25 |
| Latência p95 de API (PHP ou Go) | ≤ 200ms | ≤ 500ms | > 500ms |
| TTFB de tela do portal | ≤ 800ms | ≤ 1,8s | > 1,8s |

São pontos de partida. O orçamento real é definido com o time e registrado na especificação.

## Diagnóstico de TTFB

Quando o TTFB está lento (> 800ms), confira cada componente no waterfall da aba Network do DevTools:

- [ ] **Resolução DNS / TCP / TLS** lenta → keep-alive e HTTP/2 no servidor web; `preconnect` para origens externas conhecidas (CDN de fontes, se houver)
- [ ] **Espera do servidor** (a maior parte, normalmente) → o PHP está lento: Zend_Db_Profiler (número e tempo de queries), `EXPLAIN` das queries mais lentas, Xdebug profiler em dev, chamadas externas síncronas (gateway, ERP, API Vendpago) no `init()` ou na action
- [ ] **Trabalho em todo request** → o `init()` de `Henger_Controller_Action` e os plugins do front controller rodam em toda requisição; algo caro ali multiplica por todas as telas
- [ ] **Espera por worker** → PHP-FPM com todos os workers ocupados (status do FPM, `listen queue`)

## Checklist do Portal (Frontend)

### JavaScript / jQuery
- [ ] DOM montado fora do documento (`DocumentFragment` ou string única) e inserido uma vez, não `.append()` por item
- [ ] Delegação de eventos (`$(container).on('click', '.seletor', fn)`) em tabelas e listas, não um handler por linha
- [ ] Handlers registrados uma vez; sem `.on()` repetido a cada recarga via AJAX (vazamento e execução duplicada)
- [ ] Inputs de filtro/autocomplete com debounce (~300ms) e `jqXHR.abort()` da requisição anterior
- [ ] Sem layout thrashing: leituras (`.width()`, `.offset()`, `.height()`) agrupadas antes das escritas (`.css()`, `.addClass()`)
- [ ] Long tasks (> 50ms) quebradas: processe listas grandes em lotes com `setTimeout(fn, 0)` ou `requestAnimationFrame`, ou pagine no servidor
- [ ] Trabalho não urgente (log, pré-carregamento) fora do handler do clique, com `requestIdleCallback` quando disponível
- [ ] Seletores cacheados em variável quando reusados em loop (`var $tabela = $('#tabela');`)
- [ ] Scripts no fim do `<body>` ou com `defer`; nada bloqueante no `<head>` sem necessidade
- [ ] Plugins/libs carregados só nas telas que os usam, não no layout global
- [ ] Tabelas grandes paginadas no servidor; plugins de tabela no cliente com milhares de linhas evitados

### CSS / Sass
- [ ] Build de produção comprimido (`sass --style=compressed`) e sem source map público
- [ ] Uma entry (`frontend/scss/entries/`) por tela; componentes via `@use`, sem várias entries com componentes duplicados na mesma página
- [ ] Estilos da tela sob a classe raiz da página, sem seletores globais caros ou profundos
- [ ] Animações só com `transform` e `opacity`
- [ ] CSS por tela < 50KB gzip

### Fontes
- [ ] Fontes de ícone (`material-symbols`, `material-icons`) limitadas ao estilo/peso usado; WOFF2
- [ ] `font-display: swap` em fontes de texto (`block` curto em fontes de ícone, para não exibir o nome do ícone)
- [ ] Fontes críticas com `<link rel="preload" as="font" type="font/woff2" crossorigin>`
- [ ] Fontes servidas do próprio domínio quando possível (CDN externa adiciona DNS + TCP + TLS)
- [ ] Pilha de fontes do sistema considerada antes de uma fonte customizada

### Imagens
- [ ] `width` e `height` explícitos (evita CLS)
- [ ] `loading="lazy"` e `decoding="async"` abaixo da dobra; sem lazy na imagem principal
- [ ] Formato moderno (WebP) e tamanho adequado à exibição; logos em SVG

### Rede e cache HTTP
- [ ] URLs de JS/CSS versionadas (parâmetro de versão do layout, ex.: `vsJsCss`, ou hash no nome) e servidas com `Cache-Control` longo
- [ ] Compressão gzip/brotli no servidor web para HTML, JS, CSS e JSON
- [ ] Respostas AJAX com só os campos usados pela tela, não linhas inteiras do banco
- [ ] Sem redirects desnecessários
- [ ] HTML sem `Cache-Control: no-store` quando não houver dado sensível, e sem handlers `unload` (preserva o back/forward cache)

## Checklist de Backend PHP

### Runtime
- [ ] OPcache ligado em produção; deploy reseta o cache quando `validate_timestamps=0`
- [ ] `composer install --no-dev --optimize-autoloader` em produção
- [ ] `include_path` do Zend curto, com as pastas mais usadas primeiro
- [ ] Xdebug **desligado** em produção
- [ ] PHP-FPM: `pm.max_children × servidores × conexões por requisição + crons` < `max_connections` do PostgreSQL
- [ ] Nada caro em `init()`/plugins que rodam em toda requisição

### Acesso a dados (Zend_Db)
- [ ] Sem N+1: nenhum `find()`, `fetchRow()`, `findParentRow()`, `findDependentRowset()` ou query dentro de loop; JOIN ou `IN (?)` em lote
- [ ] Listagens e APIs paginadas (`limitPage`, ou keyset para varreduras grandes)
- [ ] `from()` com lista de colunas, não `*`, em tabelas largas
- [ ] Filtros de data como range (`>= inicio AND < fim`), não `date(coluna) = ?`
- [ ] Conexão com o banco do operador aberta só quando o fluxo precisa dela
- [ ] Transações curtas: sem chamada HTTP externa, e-mail ou geração de arquivo dentro da transação

### Crons, relatórios e exportações
- [ ] Volume grande lido com cursor no servidor (`DECLARE ... CURSOR` + `FETCH n`) ou keyset em lotes; o `pdo_pgsql` do PHP 7.4 bufferiza o resultado inteiro
- [ ] Escrita em streaming (OpenSpout) em vez de montar a planilha inteira em memória (PHPExcel)
- [ ] `memory_get_peak_usage(true)` logado e estável em relação ao volume
- [ ] Execução não sobrepõe a próxima agendada (lock de execução) e termina bem antes dela
- [ ] Chamadas externas por item agrupadas em lote quando a API permitir

### Integrações externas (Guzzle)
- [ ] `connect_timeout` e `timeout` explícitos em toda chamada
- [ ] Um client reutilizado por processo/fluxo, não um `new Client()` por item em loop
- [ ] Chamadas lentas fora da requisição do usuário (cron/fila) quando o fluxo permitir
- [ ] Retry só com idempotência garantida e backoff; nunca em operação financeira sem chave de idempotência

## Checklist de PostgreSQL

### Planos de execução
- [ ] `EXPLAIN (ANALYZE, BUFFERS)` capturado **antes** da correção, não só depois: é a baseline
- [ ] Em `UPDATE`/`DELETE`, o `EXPLAIN ANALYZE` roda dentro de `BEGIN; ... ROLLBACK;` (ele executa a query)
- [ ] Rodado em banco local/de teste com volume representativo; nunca em produção sem autorização
- [ ] `Seq Scan` em tabela grande entendido: índice ausente, inutilizável ou genuinamente não compensa
- [ ] `rows=` estimado vs. real dentro de uma ordem de grandeza (se não, `ANALYZE tabela` antes de mexer em índices)
- [ ] Nenhum nó `Sort` que um índice composto poderia absorver
- [ ] Plano conferido de novo depois da mudança: um índice que não mudou o plano é revertido

### Estratégia de índices
- [ ] Ordem das colunas do índice composto: igualdade primeiro, depois range/ordenação (ex.: `(id_operador, data_venda DESC)`)
- [ ] O índice cobre o formato da query (filtro + ordenação), não uma coluna isolada
- [ ] Índice de cobertura (`INCLUDE`) considerado em caminhos quentes de leitura (index-only scan)
- [ ] Sem índice em coluna de baixa seletividade *para o valor dominante*; índice parcial para o valor raro (`WHERE status = 'pendente'`)
- [ ] Índice de expressão onde a query aplica função (`lower(email)`), ou a query reescrita sem a função
- [ ] `pg_trgm` (GIN) ou full-text para busca com curinga no início, não B-tree
- [ ] Custo de escrita medido em tabelas com muita escrita (transações, medições)
- [ ] Índices não usados e duplicados removidos (`pg_stat_user_indexes`)
- [ ] Criação em produção com `CREATE INDEX CONCURRENTLY`, pelo mecanismo de publicação/migração do projeto e com aprovação

### Conexões
- [ ] PHP: teto de conexões calculado (workers × servidores × conexões por requisição + crons) contra `max_connections`
- [ ] Go: um pool por processo (`SetMaxOpenConns`, `SetMaxIdleConns`, `SetConnMaxLifetime`); `instâncias × max` < `max_connections`
- [ ] Toda query Go com `context` de timeout; todo `rows.Close()`; toda transação com `Commit` ou `Rollback`
- [ ] Esgotamento diagnosticado antes de redimensionar: descubra o que segura as conexões (`pg_stat_activity`: `idle in transaction`, queries longas)
- [ ] Muitos servidores/instâncias atrás de um pooler (pgbouncer) em vez de um `max_connections` maior
- [ ] `log_min_duration_statement` e `pg_stat_statements` disponíveis nos ambientes onde a investigação acontece

## Checklist de Backend Go

### Caminho quente
- [ ] Benchmarks (`b.Loop()`, `-benchmem`) nos caminhos que a otimização toca
- [ ] Regex, templates e tabelas de lookup compilados uma vez (nível de pacote ou construtor), não por chamada
- [ ] Slices e mapas com capacidade reservada quando o tamanho é conhecido
- [ ] `strings.Builder`/`bytes.Buffer` para concatenação em loop
- [ ] Sem conversões `[]byte` ↔ `string` repetidas no caminho quente
- [ ] `sync.Pool` e caches de objeto só com benchmark provando o ganho

### Concorrência
- [ ] Locks por chave (`keylock`) em vez de mutex global; nenhum lock segurado durante I/O
- [ ] Handler OCPP nunca bloqueia esperando comando remoto
- [ ] Toda goroutine com owner, cancelamento via `context` e espera no shutdown
- [ ] Canais e filas com capacidade finita; fila cheia é erro explícito
- [ ] Contenção medida com mutex/block profile antes de reestruturar locks
- [ ] `make race` verde depois de qualquer mudança em concorrência

### Memória e recursos
- [ ] Mapas indexados por carregador/sessão têm remoção quando a entidade sai
- [ ] Heap profile (`inuse_space`) estável ao longo do tempo sob carga constante
- [ ] Contagem de goroutines estável (perfil `goroutine`) depois de conectar/desconectar carregadores
- [ ] `http.Client` e transport reutilizados; `resp.Body` sempre fechado e drenado
- [ ] Tickers parados (`Stop`) e timers sem vazamento
- [ ] `GOMEMLIMIT` definido em ambiente com limite de memória (container)
- [ ] pprof exposto só em porta interna/autenticada

## Estratégias de Cache

O material de decisão (qual camada, qual estratégia de invalidação, o que nunca cachear) está na skill `performance-optimization`. Esta seção cobre os padrões de leitura/escrita e o checklist.

### Padrões de leitura e escrita

| Padrão | Como funciona | Use quando | Cuidado com |
|---|---|---|---|
| **Cache-aside** (lazy) | A aplicação consulta o cache; no miss, lê a origem e popula | Escolha padrão; leitura intensa, tolera o primeiro acesso frio | Todo miss vai à origem, então precisa de proteção contra stampede |
| **Read-through** | A própria camada de cache carrega no miss | Você quer o carregamento num lugar só, não em cada ponto de chamada | Esconde a latência da origem; uma origem lenta parece cache lento |
| **Write-through** | A escrita vai ao cache e à origem juntos, de forma síncrona | Leituras nunca podem ver valor velho depois de uma escrita | Adiciona a latência do cache a toda escrita |
| **Write-behind** (write-back) | A escrita vai ao cache e a origem é atualizada depois | Escrita intensa, com a origem como gargalo | Janela de perda de dados se o cache cair antes do flush. **Nunca em dado financeiro ou de sessão de recarga** |

### Cache negativo

Cacheie também a *ausência* de resultado. Uma chave que erra em toda consulta (um terminal/carregador inexistente consultado em loop, um cadastro que não existe) manda toda requisição à origem, e aí o cache só protege o caminho feliz.

- Guarde um sentinela explícito de "não encontrado" com TTL **menor** que o das entradas positivas
- Mantenha o TTL negativo curto o bastante para que um registro recém-criado apareça logo
- Nunca deixe um *erro* da origem virar entrada negativa, ou um minuto de falha vira muitos

### Coalescing de requisições (proteção contra stampede)

Um recálculo, N esperando. Impede que a expiração de uma chave quente entregue toda a carga concorrente à origem.

**PHP** (`Zend_Cache` + `flock`, por servidor):

```php
function carregarComLock(Zend_Cache_Core $cache, string $chave, int $ttl, callable $calcular, string $dirLocks) {
    $valor = $cache->load($chave);
    if ($valor !== false) {
        return $valor;
    }
    $lock = fopen($dirLocks . '/' . md5($chave) . '.lock', 'c');
    flock($lock, LOCK_EX);
    try {
        $valor = $cache->load($chave); // outro processo pode ter calculado enquanto esperávamos
        if ($valor === false) {
            $valor = $calcular();
            $cache->save($valor, $chave, [], $ttl);
        }
        return $valor;
    } finally {
        flock($lock, LOCK_UN);
        fclose($lock);
    }
}
```

Com vários servidores, o equivalente compartilhado é um advisory lock do PostgreSQL (`SELECT pg_advisory_xact_lock(hashtext(?))` dentro de uma transação curta).

**Go** (sem dependência nova; `golang.org/x/sync/singleflight` faz o mesmo, mas requer aprovação):

```go
type inFlightCall struct {
	done  chan struct{}
	value TerminalSummary
	err   error
}

type summaryCoalescer struct {
	mu       sync.Mutex
	inFlight map[string]*inFlightCall
}

func (c *summaryCoalescer) Load(ctx context.Context, key string, fetch func(context.Context) (TerminalSummary, error)) (TerminalSummary, error) {
	c.mu.Lock()
	if call, ok := c.inFlight[key]; ok {
		c.mu.Unlock()
		select {
		case <-call.done:
			return call.value, call.err
		case <-ctx.Done():
			return TerminalSummary{}, ctx.Err()
		}
	}
	call := &inFlightCall{done: make(chan struct{})}
	c.inFlight[key] = call
	c.mu.Unlock()

	call.value, call.err = fetch(ctx)
	c.mu.Lock()
	delete(c.inFlight, key)
	c.mu.Unlock()
	close(call.done)
	return call.value, call.err
}
```

Quem chega primeiro usa o próprio `ctx` na busca: se ele for cancelado, os que esperam recebem o erro. Quando isso não for aceitável, rode a busca com um contexto próprio, com timeout, desacoplado do chamador.

### Checklist de cache
- [ ] A chamada cacheada foi medida como cara primeiro (cachear chamada rápida adiciona um salto e não rende nada)
- [ ] A proporção leitura/escrita justifica o cache (relido muito mais do que escrito)
- [ ] A chave inclui toda entrada da qual a resposta depende: operador/cliente, banco (central/operador), usuário, nível/permissões, idioma, parâmetros do filtro
- [ ] Nenhum dado por usuário/operador cacheado sob uma chave que não o identifica
- [ ] Uma estratégia de invalidação escolhida (TTL, evento/tag ou chave versionada), não uma mistura acidental
- [ ] Janela aceitável de dado velho escrita, não implícita no TTL que alguém digitou
- [ ] Proteção contra stampede em chaves quentes (lock, coalescing ou servir valor velho enquanto recalcula)
- [ ] Resultados negativos com TTL menor; erros da origem nunca cacheados
- [ ] Limite de memória/disco e política de expiração definidos (cache sem limite é vazamento de memória; `Zend_Cache` `File` precisa de limpeza)
- [ ] Taxa de acerto observada: um cache que ninguém mede é uma suposição, e taxa baixa é só custo
- [ ] Nada cacheado cujo dado velho seja bug de correção: saldo, status de transação/pré-autorização, permissões/ACL, estado de sessão de recarga, disponibilidade de conector

## Comandos de Medição

### Portal (DevTools)

1. **Reproduza com dados reais de volume**: a tela com 50 linhas no ambiente local não mostra o problema de 5.000 linhas do operador
2. **Grave um trace** na aba Performance enquanto interage (ou use o Chrome DevTools MCP pela skill `browser-testing-with-devtools`); procure long tasks disparadas por cliques e digitação
3. **Simule hardware mais lento**: throttling de CPU 4×–6× no DevTools, porque INP ruim costuma aparecer só em máquinas mais fracas
4. **Lighthouse** para LCP/CLS e tamanho de assets da tela

### PHP

```bash
# Tempo de resposta: mediana e cauda de 20 execuções
for i in $(seq 20); do curl -s -o /dev/null -w '%{time_total}\n' -b "$COOKIE" "$URL"; done | sort -n

# Profiler de CPU por função (somente dev); gera cachegrind.out.* para o KCachegrind/QCachegrind
php -d xdebug.mode=profile -d xdebug.output_dir=/tmp/xdebug cli.php <rotina>

# Status do OPcache
php -r 'var_export(opcache_get_status(false));'   # via FPM, exponha só em rota interna
```

```php
// Número e tempo de queries de um fluxo (dev/teste)
$db->getProfiler()->setEnabled(true);
// ... executa ...
foreach ($db->getProfiler()->getQueryProfiles() ?: [] as $perfil) {
    $this->logger->debug('db.query', ['ms' => (int) ($perfil->getElapsedSecs() * 1000), 'sql' => $perfil->getQuery()]);
}
```

### PostgreSQL

```sql
-- Plano com tempo real e uso de buffers
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;

-- Queries mais caras no total (requer a extensão pg_stat_statements)
SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time) AS media_ms, query
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 20;

-- Quem está segurando conexões
SELECT state, count(*), max(now() - state_change) AS mais_antiga
FROM pg_stat_activity GROUP BY state;

-- Índices que nunca são usados
SELECT relname, indexrelname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

### Go

```bash
# Benchmark repetido e comparação estatística
go test ./internal/<pacote>/ -run '^$' -bench . -benchmem -count=10 > antes.txt
# ... aplica a mudança ...
go test ./internal/<pacote>/ -run '^$' -bench . -benchmem -count=10 > depois.txt
go run golang.org/x/perf/cmd/benchstat@latest antes.txt depois.txt

# Perfis a partir do benchmark
go test ./internal/<pacote>/ -run '^$' -bench . -cpuprofile cpu.out -memprofile mem.out
go tool pprof -top cpu.out
go tool pprof -sample_index=alloc_space -top mem.out

# Trace de execução (latência, scheduler, bloqueios)
go test ./internal/<pacote>/ -run '^$' -bench . -trace trace.out && go tool trace trace.out

# Processo em execução, com pprof numa porta interna
go tool pprof http://127.0.0.1:6060/debug/pprof/heap
go tool pprof http://127.0.0.1:6060/debug/pprof/goroutine
```

Nunca meça com `-race`, e não commite `cpu.out`/`mem.out`/`trace.out`.

## Anti-Padrões Comuns

| Anti-padrão | Impacto | Correção |
|---|---|---|
| Consultas N+1 (`find()` em loop, `findParentRow`) | Carga no banco cresce linearmente | JOIN ou `IN (?)`/`= ANY($1)` em lote |
| Consultas sem limite (`fetchAll` sem `LIMIT`) | Memória esgotada, timeouts | Paginação, keyset, cursor no servidor |
| Função na coluna do WHERE (`date(data_venda)`) | Índice ignorado, seq scan | Reescrever como range ou índice de expressão |
| Índice criado sem ler o plano | Custo de escrita pago, ganho não comprovado | `EXPLAIN (ANALYZE, BUFFERS)` antes e depois; reverter se o plano não mudou |
| Índices redundantes ou não usados | Toda escrita paga por eles | `pg_stat_user_indexes`; remova o que ninguém lê |
| Aumentar `pm.max_children`/pool contra esgotamento | Fila muda para o PostgreSQL, `max_connections` estoura | Descobrir quem segura conexões; pooler (pgbouncer) |
| Chamada externa sem timeout ou dentro de transação | Workers e conexões presos por um serviço lento | Timeout explícito; chamada fora da transação |
| Chave de cache sem operador/usuário | Dado de um operador servido a outro | Chave com operador, banco, usuário, nível |
| Cache sem limite | Vazamento de memória/disco disfarçado de otimização | Política de expiração e teto |
| Stampede numa chave quente | Origem recebe toda a carga concorrente na expiração | Lock/coalescing ou servir o valor velho enquanto recalcula |
| PHPExcel/`fetchAll` em exportação grande | Estouro de `memory_limit` | Cursor + OpenSpout em streaming |
| `.append()` por item e handler por linha | INP ruim, telas travando | `DocumentFragment` + delegação de eventos |
| AJAX por tecla sem debounce | Carga no servidor, resultados fora de ordem | Debounce + `abort()` da requisição anterior |
| Layout thrashing | Jank, quadros perdidos | Agrupar leituras de layout, depois escritas |
| Assets sem versionamento com cache longo (ou sem cache) | Arquivo velho no cliente, ou download a cada tela | URL versionada + `Cache-Control` longo |
| Lock segurado durante I/O (Go) | Latência em cascata, handlers OCPP enfileirados | Liberar o lock antes do I/O; lock por chave |
| Goroutine sem owner/cancelamento | Vazamento de goroutines e memória | `context`, owner e espera no shutdown |
| Regex/template compilado por chamada (Go) | CPU e alocações no caminho quente | Compilar uma vez no pacote/construtor |
