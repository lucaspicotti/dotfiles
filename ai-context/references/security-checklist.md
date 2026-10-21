# Checklist de Segurança

Referência rápida de segurança para os projetos PHP 7.4 (Zend Framework 1, PSR-4, Smarty, JS vanilla/jQuery, Sass) e Go (backend hexagonal). Use junto com a skill `security-and-hardening` e com o eixo de segurança da `code-review-and-quality`. O `AGENTS.md` do repositório prevalece quando for mais específico.

## Sumário

- [Threat Model (Comece Aqui)](#threat-model-comece-aqui)
- [Checagens de Pré-Commit](#checagens-de-pré-commit)
- [Autenticação](#autenticação)
- [Autorização](#autorização)
- [Validação de Input](#validação-de-input)
- [Específico de PHP](#específico-de-php)
- [Específico de JavaScript / jQuery](#específico-de-javascript--jquery)
- [Específico de Go](#específico-de-go)
- [Headers de Segurança](#headers-de-segurança)
- [Configuração de CORS](#configuração-de-cors)
- [Proteção de Dados](#proteção-de-dados)
- [Segurança de Dependências](#segurança-de-dependências)
- [Segurança de IA / LLM](#segurança-de-ia--llm)
- [Tratamento de Erros](#tratamento-de-erros)
- [Referência Rápida OWASP Top 10](#referência-rápida-owasp-top-10)
- [Referência Rápida OWASP Top 10 para LLMs](#referência-rápida-owasp-top-10-para-llms)

## Threat Model (Comece Aqui)

Antes de partir para os controles, passe cinco minutos pensando como atacante:

- [ ] Fronteiras de confiança mapeadas: requisições do portal, APIs (`V1`, `AppV2`, ...), mensagens OCPP, uploads, webhooks, respostas de gateway/ERP, arquivos lidos por cron, saída de LLM, valores escritos por processos que você não controla
- [ ] Ativos nomeados: credenciais, dados de cartão, chaves de gateway, saldo/transações, dados de outro operador, comandos remotos de carregador, ações administrativas
- [ ] STRIDE aplicado por fronteira (Spoofing, Tampering, Repudiation, Information disclosure, DoS, Elevation)
- [ ] Casos de abuso escritos ao lado dos casos de uso ("como eu abusaria disso?"), com IDOR entre operadores como caso padrão

## Checagens de Pré-Commit

- [ ] Sem segredos no diff: `git diff --cached | grep -iE "password|senha|secret|api_key|apikey|token|PRIVATE KEY"`
- [ ] `.gitignore` cobre `.env`, `.env.local`, `.env.*.local`, `*.pem`, `*.key`
- [ ] `.env.example` (Go) só com placeholders e atualizado com variáveis novas
- [ ] `.ini` versionados (`config.ini`, `vendpago.ini`) sem credencial real nova
- [ ] Fixtures e mocks (Mockoon, `testdata/`) só com dados sintéticos
- [ ] Artefatos gerados fora do commit (`bin/`, `cover.out`, CSS compilado quando o projeto não o versiona)

## Autenticação

- [ ] Senhas com `password_hash(PASSWORD_DEFAULT)` / `password_verify` (PHP) ou bcrypt custo ≥ 12 / argon2id (Go)
- [ ] Hashes legados (`md5`/`sha1`) migrados no login com `password_needs_rehash` ou verificação legada seguida de re-hash
- [ ] Cookie de sessão: `httponly`, `secure`, `samesite=Lax` (ou `Strict`), `session.use_strict_mode=1`
- [ ] `Zend_Session::regenerateId()` após login bem-sucedido
- [ ] Expiração de sessão configurada (ociosa e absoluta)
- [ ] Rate limiting no login (≤ 10 tentativas a cada 15 minutos), com store compartilhado se houver mais de um servidor
- [ ] Tokens de redefinição de senha: gerados com `random_bytes`/`crypto/rand`, com validade (≤ 1 hora), uso único, guardados como hash
- [ ] Comparações de token/assinatura em tempo constante (`hash_equals`, `subtle.ConstantTimeCompare`)
- [ ] APIs máquina-a-máquina autenticam cada requisição (assinatura/credencial da base REST da versão), validando expiração e escopo
- [ ] OCPP: security profile definido (Basic Auth sobre TLS ou mTLS), ou o risco de carregador autodeclarado registrado explicitamente

## Autorização

- [ ] Toda action do portal chama `checkPerm($recurso, $privilegio)` (ou herda uma base que o faça)
- [ ] Todo acesso a registro filtra pelo dono (operador/cliente/usuário) **na query**, contra IDOR
- [ ] O operador e o banco (central/operador) vêm da identidade autenticada, nunca direto de parâmetro do request
- [ ] Registro de outro dono responde 404, sem confirmar existência
- [ ] Endpoints administrativos exigem o nível correto; novos recursos/privilégios de ACL foram aprovados
- [ ] Go: casos de uso validam escopo (quem pode comandar qual estação/conector) antes de qualquer efeito
- [ ] Chaves de API e credenciais de integração com o mínimo de permissão necessário

## Validação de Input

- [ ] Todo input validado na fronteira (action, handler de API, adapter OCPP) e convertido para tipo/DTO antes do service
- [ ] Validação por allowlist (não denylist): enums, formatos, faixas numéricas, tamanhos mín./máx.
- [ ] Datas com `DateTimeImmutable::createFromFormat('!Y-m-d', ...)` / `time.Parse`, com intervalo coerente
- [ ] Valores monetários em centavos inteiros, validados quanto a sinal e limite
- [ ] Uploads: MIME por `finfo`, tamanho limitado, nome gerado pelo servidor, armazenados fora de `public/`
- [ ] SQL parametrizado; identificadores dinâmicos (`ORDER BY`, coluna, tabela) por allowlist
- [ ] Saída HTML escapada pelo contexto (Smarty `|escape:'html'` / `|escape:'javascript'`)
- [ ] URLs validadas antes de redirect (sem open redirect: só paths relativos ou hosts da allowlist)
- [ ] Requisições do servidor para URLs em allowlist, com IPs privados/reservados bloqueados (sem SSRF)
- [ ] Operações destrutivas em paths (delete/move/overwrite): symlinks resolvidos, raiz em allowlist, profundidade mínima, evidência de propriedade lida antes da chamada
- [ ] Exportações CSV/XLSX neutralizam células que começam com `=`, `+`, `-`, `@` (CSV injection)

### Operações Destrutivas em Paths

Contenção para um alvo nomeado por dados. Resolva primeiro, depois decida, e trate o resultado como candidato, não como autorização.

**PHP**

```php
const RAIZES_PERMITIDAS = ['/var/lib/payblu/exportacoes']; // allowlist, não padrão

function resolverAlvoRemovivel(string $candidato, string $donoEsperado): string {
    $alvo = realpath($candidato); // symlinks resolvidos ANTES da checagem
    if ($alvo === false) {
        throw new RuntimeException("Recusado: '$candidato' não existe");
    }
    foreach (RAIZES_PERMITIDAS as $raiz) {
        $raizReal = realpath($raiz);
        // o separador final exige ao menos um nível abaixo da raiz
        // e impede que '/var/lib/payblu/exportacoes-x' case com o prefixo
        if ($raizReal === false || strpos($alvo, $raizReal . DIRECTORY_SEPARATOR) !== 0) {
            continue;
        }
        $dono = @file_get_contents($alvo . DIRECTORY_SEPARATOR . '.owner');
        if ($dono === false || trim($dono) !== $donoEsperado) {
            throw new RuntimeException("Recusado: dono não comprovado para '$alvo'");
        }
        return $alvo;
    }
    throw new RuntimeException("Recusado: '$alvo' fora das raízes permitidas");
}
```

**Go** (1.24+: `os.Root`; `Root.ReadFile`/`Root.RemoveAll` desde a 1.25)

```go
// A raiz é aberta uma vez; operações via Root não escapam dela, nem por symlink.
func removeOwnedExport(root *os.Root, name, expectedOwner string) error {
	if !filepath.IsLocal(name) || filepath.Clean(name) == "." {
		return fmt.Errorf("refusing %q: expected a local path below the root", name)
	}
	owner, err := root.ReadFile(filepath.Join(name, ".owner"))
	if err != nil {
		return fmt.Errorf("refusing %q: read owner marker: %w", name, err)
	}
	if strings.TrimSpace(string(owner)) != expectedOwner {
		return fmt.Errorf("refusing %q: owner %q does not match", name, owner)
	}
	return root.RemoveAll(name)
}
```

O que isso não faz, e precisa ser dito onde o trecho for copiado:

- **O marcador é autoatestado.** Qualquer um que escreva dentro da raiz pode escrever `.owner`. O `donoEsperado` precisa vir de estado autenticado, e o marcador precisa de proteção de integridade (ownership restrito ou MAC) antes de ser autorização em vez de uma checagem de consistência contra um alvo mal derivado.
- **No PHP, retornar um path deixa uma corrida entre checagem e uso.** Onde um processo não confiável puder trocar um ancestral entre a checagem e a chamada, garanta que a hierarquia seja imutável durante a operação. O `os.Root` do Go opera relativo a um descritor e reduz esse risco.

## Específico de PHP

- [ ] Sem `unserialize()` de input (use `json_decode`, ou `['allowed_classes' => false]`)
- [ ] Sem `include`/`require` com path influenciado pelo usuário
- [ ] Sem `eval`, `create_function`, `assert` com string, `preg_replace` com `/e`
- [ ] Sem `extract($_POST)`/`extract($_REQUEST)` nem variáveis variáveis com input
- [ ] Comparações estritas (`===`, `in_array(..., true)`); tokens/hashes com `hash_equals`
- [ ] Aleatoriedade de segurança com `random_bytes`/`random_int` (nunca `rand`, `mt_rand`, `uniqid`, `md5(time())`)
- [ ] `exec`/`shell_exec`/`system`/`proc_open` evitados; se usados, `escapeshellarg` em cada argumento
- [ ] XML não confiável sem `LIBXML_NOENT`/`LIBXML_DTDLOAD` (XXE)
- [ ] Guzzle sem `'verify' => false`; com `connect_timeout` e `timeout`
- [ ] CSRF validado em toda action mutável do portal (`isCsrfValidoNaRequisicao()` onde existir); token nunca em query string
- [ ] Código novo em `src/` com `declare(strict_types=1);` e tipos declarados
- [ ] `phpSettings.display_errors = 0` e `displayExceptions = 0` em produção

## Específico de JavaScript / jQuery

- [ ] Dados de API/usuário inseridos com `.text()`, `.val()`, `textContent`, nunca `.html()`, `.append(string)`, `innerHTML`, `document.write`
- [ ] Sem `$(stringNaoConfiavel)` como seletor/HTML; sem `eval`, `new Function`, `setTimeout(string)`
- [ ] JSON passado do PHP ao JS com `json_encode(..., JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT)`
- [ ] Requisições AJAX mutáveis enviam `X-CSRF-Token`
- [ ] Nenhum token de autenticação ou dado sensível em `localStorage`/`sessionStorage`
- [ ] Versão do jQuery e plugins vendorizados em `public/scripts/` conhecida e checada contra CVEs (XSS em `.html()` antes da 3.5)
- [ ] `target="_blank"` com `rel="noopener noreferrer"`

## Específico de Go

- [ ] `http.Server` com `ReadHeaderTimeout` e `MaxHeaderBytes`; deadlines por mensagem em conexões WebSocket longas
- [ ] Corpo limitado com `http.MaxBytesReader`; JSON com `DisallowUnknownFields` quando o contrato for fechado
- [ ] Limite de tamanho de mensagem no WebSocket OCPP e número finito de conexões/fila
- [ ] Formato do `chargePointID` validado antes de virar chave de mapa, lock ou campo de log
- [ ] SQL com placeholders `$1`; nunca `fmt.Sprintf` em query
- [ ] `exec.CommandContext` com argumentos separados; nunca `sh -c` com input
- [ ] `crypto/rand` para tokens; `subtle.ConstantTimeCompare` para comparações
- [ ] `tls.Config{MinVersion: tls.VersionTLS12}`; nunca `InsecureSkipVerify: true`
- [ ] Clients HTTP com `Timeout`; requisições para URLs externas com `Dialer.Control` bloqueando IPs internos e `CheckRedirect` restritivo
- [ ] `os.Getenv` somente em `internal/platform/runtime`; configuração inválida falha no startup
- [ ] Tipos sensíveis (`TechnicalToken`, `idTag`) implementam `slog.LogValuer`/`String()` redigido; logs só com campos estruturados permitidos (`chargePointId`, `action`)
- [ ] Erros internos logados com `%w`, mas nunca devolvidos crus no corpo da resposta
- [ ] `net/http/pprof` nunca exposto na porta pública
- [ ] Sem retry automático de comandos com efeito remoto (`RemoteStart`/`RemoteStop`): repetir sem reconciliação é duplicar efeito
- [ ] `make ci` verde (vet, lint, race) e `govulncheck ./...` sem achados alcançáveis

## Headers de Segurança

```
Content-Security-Policy: default-src 'self'; script-src 'self'
  (telas legadas com <script> inline: comece com Content-Security-Policy-Report-Only)
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 0  (desligado; confie na CSP)
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=()
```

Em APIs JSON (PHP ou Go), `Content-Type: application/json; charset=utf-8` + `X-Content-Type-Options: nosniff` + `Cache-Control: no-store` em respostas com dados sensíveis.

## Configuração de CORS

```php
// PHP: ecoa a origem só se estiver na allowlist da configuração
if (is_string($origem) && in_array($origem, $origensPermitidas, true)) {
    $resposta->setHeader('Access-Control-Allow-Origin', $origem, true);
    $resposta->setHeader('Vary', 'Origin', false);
}
```

```go
// Go: middleware próprio com allowlist
func corsAllowlist(allowed map[string]bool, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if origin := r.Header.Get("Origin"); allowed[origin] {
			w.Header().Set("Access-Control-Allow-Origin", origin)
			w.Header().Add("Vary", "Origin")
		}
		next.ServeHTTP(w, r)
	})
}
```

Nunca em produção: `Access-Control-Allow-Origin: *` com credenciais, nem ecoar qualquer `Origin` recebido.

## Proteção de Dados

- [ ] Campos sensíveis fora das respostas (hash de senha, tokens, chaves de gateway, dados de cartão): DTO/struct de resposta com allowlist
- [ ] Dados sensíveis fora dos logs (senhas, tokens, `idTag`, `TechnicalToken`, cartão, payload completo de gateway)
- [ ] PCI DSS: nunca armazenar PAN completo, CVV ou trilha; usar token do gateway
- [ ] PII criptografada em repouso quando exigido
- [ ] HTTPS/TLS em toda comunicação externa (gateway, ERP, S3, carregadores)
- [ ] Backups do banco criptografados
- [ ] Dados pessoais classificados, coletados com propósito declarado e minimizados
- [ ] Dados pessoais com prazo de retenção e caminho de eliminação funcional (banco central e do operador, backups, `Zend_Cache`, exportações no S3)
- [ ] Direitos do titular (LGPD) atendidos onde exigido; compartilhamento com terceiros com base legal e contrato de tratamento

## Segurança de Dependências

Primeiro localize a **fronteira de instalação**: a raiz que tem manifesto e lockfile. Confirme que o CI (ou `composer ci:check` / `make ci`) usa o mesmo lockfile. Pare se houver lockfiles concorrentes na mesma raiz.

| Ecossistema | Instalação congelada (CI) | Auditoria de advisories conhecidos | Integridade |
|---|---|---|---|
| Composer (`composer.lock`) | `composer install --no-interaction --prefer-dist` (produção: `--no-dev --optimize-autoloader`) | `composer audit` (Composer ≥ 2.4) | `composer validate --strict` |
| npm (`package-lock.json`, build Sass) | `npm ci` | `npm audit` | `npm audit signatures` |
| Go modules (`go.mod` + `go.sum`) | `go build`/`go test` com `-mod=readonly` (padrão) | `govulncheck ./...` (considera alcançabilidade) | `go mod verify`; checksum DB `sum.golang.org` ligado para módulos públicos |

Para versões diferentes das listadas, consulte a documentação oficial do cliente fixado. Não substitua por comandos de outro gerenciador.

### Portão de Código de Terceiros na Instalação

Nunca descubra o que uma dependência executa rodando um install comum.

| Ecossistema | Onde código de terceiros roda | Política |
|---|---|---|
| Composer | **Plugins** (`type: composer-plugin`); scripts só do pacote raiz | `config.allow-plugins` explícito por pacote (nunca `true` global). Pacote novo: primeiro `composer install --no-plugins --no-scripts`, revise, depois aprove o mínimo |
| npm | Lifecycle scripts (`preinstall`, `install`, `postinstall`) | Primeiro install com `npm ci --ignore-scripts`; aprove só scripts revisados. `sass` (dart-sass puro JS) não precisa de script |
| Go | Não há scripts de instalação; `go generate`, ferramentas (`tool` no `go.mod`) e `cgo` executam código no build | Revise diretivas `//go:generate` e ferramentas novas antes de rodar; `make bootstrap` instala versões fixadas |

**Higiene de supply chain** (auditorias de advisories não pegam pacotes novos maliciosos):

- [ ] Exatamente um lockfile autoritativo por raiz, commitado; o CI nunca o reescreve
- [ ] Achados crítico/alto triados por alcançabilidade; adiamentos com motivo e data de revisão
- [ ] Correção forçada (`npm audit fix --force`, `composer update` sem restrição) nunca automática; diffs de lockfile e changelogs revisados
- [ ] Uma dependência por mudança; diff de `composer.lock`/`go.sum` revisado, inclusive transitivas
- [ ] Dependências novas revisadas quanto a dono, manutenção, idade do release, grafo transitivo, licença e typosquatting
- [ ] Inventário de código vendorizado fora do gerenciador (`library/`: Zend, Smarty, MPDF6, PHPExcel; `public/scripts/*.min.js`) com versões checadas manualmente contra advisories
- [ ] Go: dependência nova só com necessidade comprovada (regra do `AGENTS.md`) e sem vazar tipos pelas fronteiras

## Segurança de IA / LLM

Para qualquer funcionalidade que chame um LLM (chatbot, resumo, agente, RAG):

- [ ] Saída do modelo tratada como não confiável: nunca em `eval`/SQL/shell/`.html()`/path de arquivo
- [ ] Prompt injection presumida; permissões impostas no código, não no system prompt
- [ ] Segredos, dados de outros operadores e o system prompt completo fora da janela de contexto
- [ ] Permissões de ferramentas/agentes com escopo mínimo; ações destrutivas ou irreversíveis exigem confirmação
- [ ] Limites de tokens, taxa e profundidade de recursão/loop definidos
- [ ] Envio de PII a fornecedor de LLM com base legal e contrato de tratamento

## Tratamento de Erros

**PHP**

```php
// Produção: erro genérico; detalhes só no logger
$this->logger->err('Falha ao capturar venda', ['vendaId' => $id, 'excecao' => get_class($e)]);
$this->responderJsonPadrao(RespostaJson::erro('Não foi possível processar a solicitação'), 500); // ilustrativo

// NUNCA em produção:
echo $e->getMessage() . $e->getTraceAsString();   // expõe internals
echo json_encode(['erro' => $e->getMessage(), 'sql' => $select->__toString()]);
```

**Go**

```go
// Produção: log estruturado com causa, resposta genérica
logger.ErrorContext(ctx, "start charge failed", "chargePointId", cpID, "err", err)
w.Header().Set("Content-Type", "application/json")
w.WriteHeader(http.StatusInternalServerError)
_, _ = w.Write([]byte(`{"error":{"code":"INTERNAL_ERROR","message":"Something went wrong"}}`))

// NUNCA:
http.Error(w, err.Error(), http.StatusInternalServerError) // pode carregar SQL, paths, IDs internos
```

## Referência Rápida OWASP Top 10

| # | Vulnerabilidade | Prevenção nesta stack |
|---|---|---|
| 1 | Broken Access Control | `checkPerm()` + filtro de dono na query; escopo nos casos de uso Go |
| 2 | Cryptographic Failures | HTTPS/TLS ≥ 1.2, `password_hash`/bcrypt, sem segredos no código |
| 3 | Injection | `Zend_Db_Select` com `?`, PDO/`database/sql` com placeholders, modificador `escape` no Smarty |
| 4 | Insecure Design | Threat model, skill `spec-driven-development`, casos de abuso como testes |
| 5 | Security Misconfiguration | Headers, `displayExceptions = 0`, timeouts do `http.Server`, permissões mínimas |
| 6 | Vulnerable Components | `composer audit`, `govulncheck`, `npm audit`, inventário do vendorizado |
| 7 | Auth Failures | Rate limit no login, `regenerateId`, expiração de sessão, security profile OCPP |
| 8 | Data Integrity Failures | Lockfiles commitados, `go mod verify`, `allow-plugins` explícito, verificação de assinatura das APIs |
| 9 | Logging Failures | Log estruturado de eventos de segurança/financeiros, sem segredos |
| 10 | SSRF | Allowlist de URL, IPs internos bloqueados (`CURLOPT_RESOLVE` / `Dialer.Control`), sem redirects |

## Referência Rápida OWASP Top 10 para LLMs

Para aplicações com funcionalidades de LLM. Veja o [OWASP GenAI Security Project](https://genai.owasp.org/llm-top-10/).

| ID | Risco | Prevenção |
|---|---|---|
| LLM01 | Prompt Injection | Não confie no system prompt como fronteira; imponha permissões no código |
| LLM02 | Sensitive Information Disclosure | Mantenha segredos/PII fora dos prompts; filtre saídas |
| LLM03 | Supply Chain | Avalie modelos, datasets e plugins como qualquer dependência |
| LLM04 | Data and Model Poisoning | Use fontes de modelo confiáveis e verifique integridade; avalie dados de fine-tuning e RAG |
| LLM05 | Improper Output Handling | Trate a saída do modelo como não confiável; valide, parametrize, escape |
| LLM06 | Excessive Agency | Limite permissões de ferramentas; confirme ações destrutivas |
| LLM07 | System Prompt Leakage | Presuma que o system prompt pode vazar; não coloque segredos nele |
| LLM08 | Vector and Embedding Weaknesses | Particione embeddings de RAG por operador/tenant; valide documentos antes de indexar |
| LLM09 | Misinformation | Fundamente respostas com citações; valide afirmações críticas; mantenha um humano no loop |
| LLM10 | Unbounded Consumption | Limite tokens, taxa de requisição e profundidade de loop/recursão |
