# Padrões de Hardening

Padrões de código e apoios de decisão para a skill `security-and-hardening`, em PHP 7.4 (Zend Framework 1, PSR-4 em `src/`, Smarty, jQuery) e Go (backend hexagonal). A skill declara cada regra; este arquivo mostra uma implementação concreta dela. Abra a seção de que precisar quando chegar àquele código: não é para ler de ponta a ponta.

Nomes de classes, tabelas e métodos marcados como *ilustrativos* não existem necessariamente no projeto. Antes de copiar, procure o equivalente real (repository, service, helper do `Henger_*`, pacote Go) e siga o `AGENTS.md` do repositório.

Checklists compartilhados (threat model, pré-commit, headers, CORS, comandos de auditoria por ecossistema e as tabelas do OWASP) ficam em `../../../references/security-checklist.md`.

## Padrões de Prevenção do OWASP Top 10

São padrões de prevenção, não um ranking. Para a ordem de 2021, veja a tabela em `../../../references/security-checklist.md#referência-rápida-owasp-top-10`.

### Injection

**PHP (Zend_Db / PDO)**

```php
// RUIM: SQL injection por concatenação
$sql = "SELECT * FROM venda WHERE id = " . $this->_getParam('id');
$select->where("id_operador = $idOperador");

// BOM: placeholder no Zend_Db_Select
$select = $db->select()
    ->from(['v' => 'venda'], ['id', 'valor_centavos', 'status'])
    ->where('v.id = ?', (int) $id)
    ->where('v.id_operador = ?', $idOperador);

// BOM: lista em IN, o Zend expande e escapa cada item
$select->where('v.id IN (?)', array_map('intval', $ids));

// BOM: PDO puro
$stmt = $pdo->prepare('SELECT id, status FROM venda WHERE id = :id');
$stmt->execute([':id' => $id]);

// Identificadores não aceitam placeholder: use allowlist
$colunasOrdenaveis = ['data' => 'v.data_venda', 'valor' => 'v.valor_centavos'];
$coluna = $colunasOrdenaveis[$this->_getParam('ordem')] ?? 'v.data_venda';
$direcao = $this->_getParam('direcao') === 'asc' ? 'ASC' : 'DESC';
$select->order("$coluna $direcao");
```

Comandos de sistema, quando inevitáveis:

```php
// RUIM
exec("zip /tmp/export.zip " . $_POST['arquivo']);

// BOM: cada argumento escapado, e o arquivo validado antes (veja "Paths destrutivos")
exec('zip ' . escapeshellarg($destino) . ' ' . escapeshellarg($arquivoValidado), $saida, $codigo);
```

**Go (`database/sql` / pgx)**

```go
// RUIM: fmt.Sprintf monta a query com input
q := fmt.Sprintf("SELECT id FROM sessions WHERE charge_point_id = '%s'", cpID)

// BOM: placeholder posicional do PostgreSQL
row := db.QueryRowContext(ctx,
	"SELECT id, status FROM sessions WHERE charge_point_id = $1 AND connector_id = $2",
	cpID, connectorID)

// Comando externo: argumentos separados, nunca "sh -c" com input
cmd := exec.CommandContext(ctx, "/usr/bin/tool", "--id", validatedID)
```

Outros vetores de injeção específicos de PHP:

```php
// RUIM: object injection / RCE via __wakeup/__destruct de classes carregadas
$filtros = unserialize($_COOKIE['filtros']);
// BOM
$filtros = json_decode($_COOKIE['filtros'] ?? '[]', true);
// Se o legado exige serialize: sem classes
$filtros = unserialize($valor, ['allowed_classes' => false]);

// RUIM: LFI/RFI
include APPLICATION_PATH . '/views/' . $_GET['pagina'] . '.php';
// BOM: allowlist
$paginas = ['resumo' => 'resumo.php', 'extrato' => 'extrato.php'];
include APPLICATION_PATH . '/views/' . ($paginas[$pagina] ?? 'resumo.php');

// RUIM: sobrescreve variáveis locais com o que vier no POST
extract($_POST);

// RUIM: type juggling ("0e1234" == "0e9999" é true)
if ($tokenRecebido == $tokenEsperado) { }
// BOM
if (hash_equals($tokenEsperado, (string) $tokenRecebido)) { }
```

### Autenticação, Sessão e CSRF

**Senhas (PHP 7.4)**

```php
// Cadastro / troca de senha
$hash = password_hash($senha, PASSWORD_DEFAULT); // bcrypt; trunca em 72 bytes

// Login com migração transparente de hash legado (md5 de 32 hex)
if (password_verify($senha, $usuario->senha)) {
    if (password_needs_rehash($usuario->senha, PASSWORD_DEFAULT)) {
        $this->usuarioRepository->atualizarHashSenha($usuario->id, password_hash($senha, PASSWORD_DEFAULT));
    }
    return true;
}
$ehMd5Legado = preg_match('/^[0-9a-f]{32}$/', $usuario->senha) === 1;
if ($ehMd5Legado && hash_equals($usuario->senha, md5($senha))) {
    $this->usuarioRepository->atualizarHashSenha($usuario->id, password_hash($senha, PASSWORD_DEFAULT));
    return true;
}
return false;
```

**Sessão (PHP)**: configure antes de `Zend_Session::start()`, no `php.ini` ou no Bootstrap. O `Zend_Session::setOptions()` do ZF1 aceita uma lista fixa de opções. Se ele recusar `cookie_samesite`, use `ini_set`.

```php
ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_secure', '1');      // somente HTTPS
ini_set('session.cookie_samesite', 'Lax');  // PHP >= 7.3
ini_set('session.use_strict_mode', '1');    // rejeita ID de sessão não emitido pelo servidor
ini_set('session.use_only_cookies', '1');

// Após autenticar com sucesso (contra session fixation)
$resultado = Zend_Auth::getInstance()->authenticate($adapter);
if ($resultado->isValid()) {
    Zend_Session::regenerateId();
}
```

**CSRF (portal Zend)**: quando o projeto tiver os helpers em `Henger_Controller_Action` (ex.: PayBlu e MicroMarket), use-os. Se não tiver (confira no `library/Henger/Controller/Action.php` do projeto), pergunte antes de criar.

```php
public function salvarAction() {
    $this->checkPerm('configuracao-gateway', 'editar');
    if (!$this->_request->isPost() || !$this->isCsrfValidoNaRequisicao()) {
        $this->getResponse()->setHttpResponseCode(403);
        return $this->responderJsonPadrao(RespostaJson::erro('Requisição inválida'), 403); // ilustrativo
    }
    // ...
}
```

```smarty
<form method="post" action="/pay-blu-config/salvar">
    {include file='partial/csrf-token-field.tpl'}
    ...
</form>
```

AJAX: envie o token no header `X-CSRF-Token`, a partir da variável que o layout expõe (ex.: `csrfToken` no `header.tpl`, usada por `processar-ajax.js`). Nunca coloque o token em query string (ele vaza em log e em `Referer`).

**Go**: APIs máquina-a-máquina não usam cookie; autentique cada requisição.

```go
// Hash de senha/segredo de cliente (dependência golang.org/x/crypto: requer aprovação)
hash, err := bcrypt.GenerateFromPassword([]byte(secret), 12)
err = bcrypt.CompareHashAndPassword(hash, []byte(candidate))

// Comparação de token em tempo constante (stdlib)
if subtle.ConstantTimeCompare([]byte(expected), []byte(received)) != 1 {
	return ErrUnauthenticated
}

// Token aleatório (stdlib)
buf := make([]byte, 32)
if _, err := rand.Read(buf); err != nil { // crypto/rand
	return "", fmt.Errorf("generate token: %w", err)
}
token := hex.EncodeToString(buf)
```

**OCPP 1.6**: o `chargePointID` em `/ocpp/{chargePointID}` é autodeclarado. Sem um security profile (Basic Auth sobre TLS, ou TLS com certificado de cliente), qualquer cliente WebSocket se passa por qualquer carregador. Enquanto não houver, trate isso como risco registrado. Nunca aceite um carregador desconhecido como confiável só porque ele fez `BootNotification`.

### Cross-Site Scripting (XSS)

**Smarty**: sem auto-escape configurado, `{$var}` sai cru.

```smarty
{* RUIM *}
<td>{$cliente->nome}</td>
<input value="{$filtro}">
<script>var nome = "{$cliente->nome}";</script>

{* BOM: escape pelo contexto *}
<td>{$cliente->nome|escape:'html'}</td>
<input value="{$filtro|escape:'html'}">
<script>var nome = "{$cliente->nome|escape:'javascript'}";</script>
```

Para passar estruturas ao JS, prefira JSON codificado com segurança para HTML a concatenar strings:

```php
$this->view->dadosGraficoJson = json_encode(
    $dados,
    JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT
);
```

```smarty
<script>var dadosGrafico = {$dadosGraficoJson};</script>
```

**JavaScript / jQuery**

```js
// RUIM: resposta da API ou input do usuário interpretado como HTML
$('#mensagem').html(resposta.mensagem);
$('#lista').append('<li>' + item.nome + '</li>');
$(location.hash);                        // seletor vira HTML em jQuery antigo
el.innerHTML = item.descricao;
setTimeout('atualizar(' + id + ')', 500); // string é eval

// BOM
$('#mensagem').text(resposta.mensagem);
$('<li>').text(item.nome).appendTo('#lista');
$(document.getElementById(idValidado));
el.textContent = item.descricao;
setTimeout(function () { atualizar(id); }, 500);
```

A versão do jQuery importa: há CVEs de XSS em `.html()`/`htmlPrefilter` antes da 3.5 e em seletores de versões antigas (ex.: `jquery-1.7.min.js` vendorizado). Enquanto o upgrade não acontece, isso reforça a regra de nunca passar HTML não confiável para o jQuery. Se HTML cru for inevitável (ex.: conteúdo rico), sanitize com um sanitizador de allowlist (DOMPurify) antes de inserir.

**Go**: APIs retornando JSON com `Content-Type: application/json` e `X-Content-Type-Options: nosniff` não renderizam HTML. Se algum dia renderizar HTML no servidor, use `html/template` (escape contextual), nunca `text/template`.

### Controle de Acesso Quebrado (IDOR)

`checkPerm()` responde "este nível pode executar esta ação?". Ele não responde "este registro pertence ao operador/cliente do usuário?". As duas checagens são obrigatórias.

```php
public function detalheAction() {
    $this->checkPerm('vendas', 'visualizar');                 // 1. ação permitida ao nível

    $id = (int) $this->_getParam('id');
    $venda = $this->vendaRepository->buscarDoOperador(          // 2. escopo do dono na query
        $id,
        $this->operadorDoUsuarioLogado()                        // ilustrativo
    );
    if ($venda === null) {
        // 404 e não 403: não confirme a existência de registro alheio
        throw new Zend_Controller_Action_Exception('Venda não encontrada', 404);
    }
    $this->view->venda = $venda;
}
```

```php
// Repository: o filtro de dono faz parte da query, não de um if depois do fetch
public function buscarDoOperador(int $id, int $idOperador): ?array {
    $select = $this->db->select()
        ->from(['v' => 'venda'])
        ->where('v.id = ?', $id)
        ->where('v.id_operador = ?', $idOperador);
    $linha = $this->db->fetchRow($select);
    return $linha ?: null;
}
```

Lembre a distinção entre banco central e banco do operador: escolher o adapter errado a partir de um parâmetro da requisição (`cid`, `operador`) é uma forma de IDOR. O operador vem da identidade autenticada ou de uma lista autorizada para ela, nunca direto do request.

**Go**: a autorização por escopo pertence à aplicação, com vocabulário de domínio, antes de qualquer efeito colateral.

```go
// Ilustrativo: o caso de uso recebe o principal autenticado pelo adapter
func (uc *StartCharge) Execute(ctx context.Context, p Principal, cmd ports.StartCommand) (ports.CommandResult, error) {
	if !p.CanOperate(cmd.StationID) {
		return ports.CommandResult{}, fmt.Errorf("start charge on %s: %w", cmd.StationID, ErrForbidden)
	}
	// ...
}
```

### Configuração Insegura

**Headers (PHP)**: preferencialmente no vhost do servidor web. Na aplicação, um plugin do front controller cobre todas as respostas.

```php
// Ilustrativo: registrar no Bootstrap com $front->registerPlugin(...)
class Henger_Plugin_HeadersSeguranca extends Zend_Controller_Plugin_Abstract {
    public function dispatchLoopShutdown() {
        $resposta = $this->getResponse();
        $resposta->setHeader('X-Content-Type-Options', 'nosniff', true);
        $resposta->setHeader('X-Frame-Options', 'DENY', true);
        $resposta->setHeader('Referrer-Policy', 'strict-origin-when-cross-origin', true);
        $resposta->setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains', true);
        // Telas legadas usam <script> inline: comece em modo report-only e aperte depois
        $resposta->setHeader('Content-Security-Policy-Report-Only', "default-src 'self'", true);
    }
}
```

**Erros (Zend)**: em produção, `resources.frontController.params.displayExceptions = 0` e `phpSettings.display_errors = 0`. O `ErrorController` registra a exceção no logger e mostra mensagem genérica.

**CORS (API PHP)**

```php
$origensPermitidas = Zend_Registry::get('config')->cors->origens->toArray(); // ilustrativo
$origem = $this->_request->getHeader('Origin');
if (is_string($origem) && in_array($origem, $origensPermitidas, true)) {
    $this->getResponse()
        ->setHeader('Access-Control-Allow-Origin', $origem, true)
        ->setHeader('Vary', 'Origin', false);
}
// Nunca: Access-Control-Allow-Origin: * junto com credenciais
```

**Go (`http.Server`)**

```go
srv := &http.Server{
	Addr:              cfg.HTTPAddr,
	Handler:           mux,
	ReadHeaderTimeout: 5 * time.Second, // contra Slowloris (gosec G112)
	MaxHeaderBytes:    1 << 20,
	IdleTimeout:       60 * time.Second,
}
// ReadTimeout/WriteTimeout globais também se aplicam à rota WebSocket de longa duração
// (/ocpp/): prefira deadlines por mensagem no adapter e confirme o comportamento com teste.

tlsCfg := &tls.Config{MinVersion: tls.VersionTLS12}
// Nunca: InsecureSkipVerify: true
```

### Exposição de Dados Sensíveis

**PHP**: monte a resposta com allowlist.

```php
// RUIM: devolve todas as colunas, incluindo hash de senha e chave do gateway
return $this->responderJsonPadrao(RespostaJson::sucesso($row->toArray()));

// BOM: DTO/array com os campos públicos
return $this->responderJsonPadrao(RespostaJson::sucesso([
    'id'     => (int) $row->id,
    'nome'   => $row->nome,
    'status' => $row->status,
]));
```

**Go**: nunca serialize o agregado do domínio. Use um tipo de resposta do adapter e faça os tipos sensíveis se autorredigirem em log.

```go
type chargePointResponse struct {
	ID     string `json:"id"`
	Status string `json:"status"`
}

// Tipo sensível que não vaza por slog nem por %v
type TechnicalToken string

func (TechnicalToken) LogValue() slog.Value { return slog.StringValue("[REDACTED]") }
func (TechnicalToken) String() string        { return "[REDACTED]" }
```

Configuração obrigatória falha cedo, na camada de plataforma:

```go
// internal/platform/runtime: único lugar que lê o ambiente
key := os.Getenv("OCPPSERVER_GATEWAY_KEY") // ilustrativo
if key == "" {
	return Config{}, errors.New("OCPPSERVER_GATEWAY_KEY is required (non-empty string)")
}
```

### SSRF

Toda vez que o servidor busca uma URL influenciada pelo usuário (webhook configurável, "importar de URL", URL de servidor de operador cadastrada no portal), o atacante pode apontá-la para serviços internos (metadata de nuvem, `localhost`, IPs privados, o próprio PostgreSQL).

**PHP (Guzzle 7)**

```php
/** @return array{0:string,1:string} host e IP validado */
function resolverDestinoSeguro(string $url, array $hostsPermitidos): array {
    $partes = parse_url($url);
    if (($partes['scheme'] ?? '') !== 'https') {
        throw new InvalidArgumentException("URL '$url' inválida: somente https");
    }
    $host = strtolower($partes['host'] ?? '');
    if (!in_array($host, $hostsPermitidos, true)) {
        throw new InvalidArgumentException("Host '$host' fora da allowlist");
    }
    $ips = array_merge(
        array_column(dns_get_record($host, DNS_A) ?: [], 'ip'),
        array_column(dns_get_record($host, DNS_AAAA) ?: [], 'ipv6')
    );
    if ($ips === []) {
        throw new RuntimeException("Host '$host' não resolveu");
    }
    foreach ($ips as $ip) { // QUALQUER endereço privado/reservado reprova
        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) === false) {
            throw new RuntimeException("Host '$host' resolve para endereço interno '$ip'");
        }
    }
    return [$host, $ips[0]];
}

[$host, $ip] = resolverDestinoSeguro($url, $hostsPermitidos);
$porta = parse_url($url, PHP_URL_PORT) ?: 443;
$ipCurl = strpos($ip, ':') !== false ? "[$ip]" : $ip;

$resposta = $client->request('POST', $url, [
    'allow_redirects' => false,
    'connect_timeout' => 5,
    'timeout'         => 15,
    // Fixa o IP validado: fecha a lacuna de DNS rebinding entre a checagem e a conexão
    'curl'            => [CURLOPT_RESOLVE => ["$host:$porta:$ipCurl"]],
]);
```

Cubra com teste table-driven os casos `127.0.0.1`, `::1`, `::ffff:127.0.0.1`, `169.254.169.254`, `10.0.0.1`, `fd00::1`: o comportamento de `FILTER_FLAG_NO_RES_RANGE` varia entre versões do PHP.

**Go**: valide o IP no momento da conexão, com `net.Dialer.Control`. Assim a checagem vale para o IP efetivamente conectado, sem lacuna TOCTOU.

```go
func rejectInternalAddress(network, address string, _ syscall.RawConn) error {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return fmt.Errorf("split %q: %w", address, err)
	}
	ip, err := netip.ParseAddr(host)
	if err != nil {
		return fmt.Errorf("parse ip %q: %w", host, err)
	}
	ip = ip.Unmap()
	if !ip.IsGlobalUnicast() || ip.IsPrivate() || ip.IsLoopback() || ip.IsLinkLocalUnicast() {
		return fmt.Errorf("refusing internal address %s", ip)
	}
	return nil
}

dialer := &net.Dialer{Timeout: 5 * time.Second, Control: rejectInternalAddress}
client := &http.Client{
	Timeout: 15 * time.Second,
	Transport: &http.Transport{
		Proxy:       nil, // com proxy, o IP checado seria o do proxy
		DialContext: dialer.DialContext,
	},
	CheckRedirect: func(*http.Request, []*http.Request) error {
		return errors.New("redirects are not allowed")
	},
}
// Continue validando esquema e host por allowlist antes de montar a requisição.
```

`netip` não classifica CGNAT (`100.64.0.0/10`) nem outros blocos especiais como privados. Adicione prefixos à lista se a sua rede os usar.

## Padrões de Validação de Input

### Validação na Fronteira

**PHP (código PSR-4 em `src/`)**

```php
declare(strict_types=1);

namespace App\Http; // ilustrativo

final class FiltroRelatorioVendas {
    private const STATUS_VALIDOS = ['aprovada', 'cancelada', 'pendente'];

    /** @var \DateTimeImmutable */ private $inicio;
    /** @var \DateTimeImmutable */ private $fim;
    /** @var string */ private $status;

    public static function deRequisicao(array $params): self {
        $inicio = \DateTimeImmutable::createFromFormat('!Y-m-d', (string) ($params['inicio'] ?? ''));
        $fim = \DateTimeImmutable::createFromFormat('!Y-m-d', (string) ($params['fim'] ?? ''));
        if ($inicio === false || $fim === false || $inicio > $fim) {
            throw new ParametroInvalidoException("Período inválido: esperado inicio <= fim em Y-m-d");
        }
        $status = (string) ($params['status'] ?? 'aprovada');
        if (!in_array($status, self::STATUS_VALIDOS, true)) {
            throw new ParametroInvalidoException("Status '$status' inválido: esperado " . implode('|', self::STATUS_VALIDOS));
        }
        $filtro = new self();
        [$filtro->inicio, $filtro->fim, $filtro->status] = [$inicio, $fim, $status];
        return $filtro;
    }
}
```

No controller, `ParametroInvalidoException` vira HTTP 422 com detalhes estruturados. O service recebe o objeto tipado, nunca `$this->_getAllParams()`.

**Go (futuro handler REST)**

```go
type createTariffRequest struct {
	Name        string `json:"name"`
	PricePerKWh int64  `json:"pricePerKWhCents"`
}

func decodeCreateTariff(w http.ResponseWriter, r *http.Request) (createTariffRequest, error) {
	var req createTariffRequest
	r.Body = http.MaxBytesReader(w, r.Body, 64<<10)
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	if err := dec.Decode(&req); err != nil {
		return req, fmt.Errorf("decode create tariff: %w", err)
	}
	if req.Name == "" || len(req.Name) > 100 {
		return req, fmt.Errorf("name %q: expected 1..100 chars", req.Name)
	}
	if req.PricePerKWh <= 0 {
		return req, fmt.Errorf("pricePerKWhCents %d: expected > 0", req.PricePerKWh)
	}
	return req, nil
}
```

Para o OCPP: valide o formato do `chargePointID` (allowlist de caracteres e tamanho máximo do contrato) antes de usá-lo como chave de mapa, nome de lock ou campo de log. Limite o tamanho de mensagem do WebSocket e confirme se o `ocpp-go` expõe esse limite.

### Upload de Arquivos

```php
private const TAMANHO_MAXIMO = 5 * 1024 * 1024; // 5 MB
private const EXTENSAO_POR_MIME = ['image/jpeg' => '.jpg', 'image/png' => '.png', 'application/pdf' => '.pdf'];

public function receberComprovante(array $arquivo): string {
    if (($arquivo['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK || !is_uploaded_file($arquivo['tmp_name'])) {
        throw new ParametroInvalidoException('Upload ausente ou com erro');
    }
    if ($arquivo['size'] > self::TAMANHO_MAXIMO) {
        throw new ParametroInvalidoException("Arquivo com {$arquivo['size']} bytes: máximo 5 MB");
    }
    // $_FILES['type'] vem do cliente; finfo lê os magic bytes
    $mime = (new finfo(FILEINFO_MIME_TYPE))->file($arquivo['tmp_name']);
    if (!isset(self::EXTENSAO_POR_MIME[$mime])) {
        throw new ParametroInvalidoException("Tipo '$mime' não permitido");
    }
    $nome = bin2hex(random_bytes(16)) . self::EXTENSAO_POR_MIME[$mime]; // nunca o nome do cliente
    $destino = $this->diretorioForaDoPublic . '/' . $nome;
    if (!move_uploaded_file($arquivo['tmp_name'], $destino)) {
        throw new RuntimeException("Falha ao mover upload para '$destino'");
    }
    return $nome;
}
```

Downloads saem por uma action com `checkPerm()` e escopo de dono, com `Content-Disposition: attachment` e `X-Content-Type-Options: nosniff`, nunca por link direto em `public/`.

**Exportações CSV/XLSX (OpenSpout, PHPExcel)**: valores do usuário que começam com `=`, `+`, `-`, `@`, tab ou CR viram fórmula ao abrir no Excel (CSV injection). Prefixe com `'` ou exporte a célula como texto.

### Operações Destrutivas em Paths Derivados

Um delete, move ou overwrite é tão seguro quanto o valor que nomeia o alvo. Ler esse valor do kernel, de um payload de job ou de um serviço vizinho prova de onde ele *chegou*, não quem o *escreveu*: a linha de comando de outro processo é tão controlada pelo atacante quanto um campo de formulário. Uma checagem de formato ("path absoluto, pelo menos um diretório de profundidade") prova boa formação e é confundida com autorização. É assim que uma rotina de limpeza apaga a raiz em vez da folha.

Antes de uma chamada destrutiva, exija as três coisas:

1. O alvo resolvido está sob uma **raiz em allowlist**. Compare depois de resolver symlinks (`realpath()`, `filepath.EvalSymlinks`), nunca na string crua.
2. O alvo está pelo menos um nível **abaixo** dessa raiz, então a raiz nunca é o alvo.
3. O alvo carrega **evidência de que é seu**, lida *antes* da operação e antes de qualquer teardown que a remova. Sem isso, "ausente" e "não é meu" ficam indistinguíveis.

Em caso de recusa, registre o alvo rejeitado e pare. Uma limpeza que recorre a um path padrão mais amplo é exatamente a falha que isso evita. Exemplos completos em PHP e Go: `../../../references/security-checklist.md#operações-destrutivas-em-paths`.

Dois limites, porque a checagem parece mais forte do que é:

- **Um marcador dentro da árvore é autoatestado.** Qualquer um que possa escrever ali pode escrever o marcador. O dono esperado precisa vir de estado autenticado, e o marcador precisa de proteção de integridade (ownership restrito ou um MAC) antes de valer como autorização.
- **Resolver um path e depois operar sobre o *nome* é uma corrida entre checagem e uso** onde um processo não confiável puder trocar um ancestral. Em volume compartilhado, no Go use `os.Root` (operações relativas a um descritor, que não escapam da raiz). No PHP, que não tem equivalente, garanta que a hierarquia não mude durante a operação (diretório de propriedade exclusiva do usuário do serviço).

## Triagem de Auditoria de Dependências

Auditorias reportam advisories conhecidos; não provam que um pacote é confiável nem que o código vulnerável é alcançável. Use esta árvore de decisão:

```
A auditoria nativa (composer audit / govulncheck / npm audit) reporta uma vulnerabilidade
├── Severidade: crítica ou alta
│   ├── O código vulnerável é alcançável em runtime, build, teste ou deploy?
│   │   ├── govulncheck: "Your code is affected" / símbolo na call stack → alcançável
│   │   ├── composer/npm: confira se a função vulnerável é usada e se o pacote é de runtime
│   │   ├── SIM → Corrija já (atualize, aplique patch ou substitua a dependência)
│   │   └── NÃO (confirmado sem uso nesses caminhos) → Corrija logo, mas não bloqueia
│   └── Existe correção?
│       ├── SIM → Atualize para a versão corrigida (uma dependência por mudança)
│       └── NÃO → Busque workaround, avalie substituir, ou registre exceção com data de revisão
├── Severidade: moderada
│   ├── Alcançável em produção? → Corrija no próximo ciclo de release
│   └── Só dev/build (ex.: sass do build de CSS)? → Corrija quando conveniente, registre no backlog
└── Severidade: baixa
    └── Registre e corrija nas atualizações regulares de dependências
```

**Perguntas-chave:**

- A função vulnerável é de fato chamada no seu caminho de código?
- A dependência é de runtime (`require`) ou só de desenvolvimento (`require-dev`, `devDependencies`)?
- A vulnerabilidade é explorável no seu contexto? Por exemplo, uma falha de navegador num pacote usado só para compilar Sass.
- O componente está **fora** do gerenciador (`library/`, `public/scripts/*.min.js`)? Então nenhuma auditoria o verá: verifique a versão contra advisories manualmente.

Ao adiar uma correção, documente o motivo e defina uma data de revisão.

## Rate Limiting

**PHP**: contador compartilhado no PostgreSQL. A tabela é ilustrativa e exige migração/publicação aprovada.

```php
// janela fixa de 15 minutos, atômica via upsert
$sql = 'INSERT INTO limite_tentativa (chave, janela, total) VALUES (?, ?, 1)
        ON CONFLICT (chave, janela) DO UPDATE SET total = limite_tentativa.total + 1
        RETURNING total';
$janela = intdiv(time(), 15 * 60);
$total = (int) $db->fetchOne($sql, ['login:' . $_SERVER['REMOTE_ADDR'], $janela]);
if ($total > 10) {
    $this->getResponse()->setHttpResponseCode(429)->setHeader('Retry-After', '900', true);
    return;
}
```

Atrás de proxy/balanceador, `REMOTE_ADDR` é o IP do proxy. Só confie em `X-Forwarded-For` vindo de proxies conhecidos. Limite também por usuário/login, não só por IP. Um job de limpeza remove janelas antigas.

**Go**: por chave, em memória. `golang.org/x/time/rate` é uma dependência e requer aprovação.

```go
type keyedLimiter struct {
	mu       sync.Mutex
	limiters map[string]*rate.Limiter
}

func (k *keyedLimiter) Allow(key string) bool {
	k.mu.Lock()
	defer k.mu.Unlock()
	l, ok := k.limiters[key]
	if !ok {
		l = rate.NewLimiter(rate.Every(90*time.Second), 10) // ~10 por 15 min
		k.limiters[key] = l
	}
	return l.Allow()
}
```

Esse mapa cresce sem limite: remova chaves ociosas e limite o total de chaves. Ele vale por instância; com mais de uma réplica, use um store compartilhado (PostgreSQL, quando existir) ou aceite `max × réplicas` explicitamente. No OCPP, aplique o mesmo por `chargePointID` para mensagens recebidas e limite conexões simultâneas.

## Gestão de Segredos

```
PHP (Zend):
  ├── application/config.ini, vendpago.ini → VERSIONADOS: só valores não secretos/placeholders
  ├── arquivo local de override (não versionado) ou variáveis de ambiente lidas no Bootstrap
  └── credenciais expostas via Zend_Registry para os services/clients

Go:
  ├── .env.example → versionado (placeholders), atualizado a cada nova variável
  ├── .env         → NÃO versionado
  └── leitura só em internal/platform/runtime (LoadConfig)

.gitignore deve incluir:
  .env
  .env.local
  .env.*.local
  *.pem
  *.key
```

**Sempre confira antes de commitar:**

```bash
git diff --cached | grep -iE "password|senha|secret|api_key|apikey|token|BEGIN .*PRIVATE KEY"
```

Fixtures e mocks (ex.: Mockoon em `tests/mocks/`) usam valores totalmente sintéticos: nada de chave real de sandbox, cartão real ou credencial copiada de homologação.

**Se um segredo for commitado, rotacione-o.** Apagar a linha ou reescrever o histórico não basta: assuma que ele foi comprometido no momento em que chegou ao remoto. Revogue e reemita a chave primeiro; depois limpe o histórico.

## Classificação de Dados

Classifique dados pessoais ao adicionar campos, para que pedidos de acesso e eliminação (LGPD) os encontrem depois:

| Classe | Exemplos | Tratamento |
|---|---|---|
| **Não pessoal** | Agregados, contagens anonimizadas, status de terminal | Tratamento normal |
| **Pessoal (PII)** | Nome, e-mail, telefone, CPF, IP, ID de dispositivo, `idTag` vinculado a pessoa | Minimize, controle acesso, inclua em exportação/eliminação, fora de logs |
| **Sensível / regulado** | Dados de cartão (PCI DSS: nunca PAN completo, CVV ou trilha), dados financeiros, localização precisa, dados de menores, biometria | Base legal reforçada, acesso mais restrito, geralmente criptografia e log de auditoria |

## Saída de LLM

```php
// RUIM: saída do modelo tratada como comando ou markup
$sql = $llm->gerar("Escreva SQL para: $pergunta");
$db->query($sql);                                    // execução arbitrária
$this->view->resposta = $llm->responder($mensagem);  // e o template imprime sem escape

// BOM: saída do modelo é dado; parse defensivo, valide, depois escape
$intencao = json_decode($llm->responderJson($mensagem), true);
if (!is_array($intencao) || !in_array($intencao['acao'] ?? null, self::ACOES_PERMITIDAS, true)) {
    throw new ParametroInvalidoException('Saída inesperada do modelo');
}
$this->executarAcaoPermitida($intencao['acao'], $intencao['parametros'] ?? []);
```

```go
var intent assistantIntent
if err := json.Unmarshal(raw, &intent); err != nil {
	return fmt.Errorf("decode model output: %w", err)
}
if _, ok := allowedActions[intent.Action]; !ok {
	return fmt.Errorf("model action %q: not in allowlist", intent.Action)
}
```
