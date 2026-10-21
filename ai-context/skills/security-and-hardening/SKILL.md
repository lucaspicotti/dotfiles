---
name: security-and-hardening
description: "Protege o código contra vulnerabilidades nos projetos PHP 7.4 (Zend Framework 1, PSR-4, APIs REST, Smarty, JS vanilla/jQuery) e Go (backend hexagonal, OCPP). Use ao auditar um handler de entrada, ao tratar input do usuário, autenticação, sessão, ACL, CSRF, armazenamento de dados ou integrações externas, ou ao checar um fluxo de login contra o OWASP Top 10. Use ao construir qualquer funcionalidade que aceite dados não confiáveis (formulários, APIs, mensagens OCPP, webhooks, uploads). Use ao auditar dependências (`composer audit`, `govulncheck`, `npm audit`), triar achados ou avaliar risco de supply chain de um pacote novo. Use quando dados pessoais ou LGPD estiverem envolvidos."
---

# Segurança e Hardening

## Visão Geral

Práticas de desenvolvimento com segurança em primeiro lugar para os dois ecossistemas da casa:

- **PHP 7.4** (confirme a versão no `composer.json` do projeto): monólitos Zend Framework 1.x com controllers `Henger_Controller_Action`, APIs REST versionadas em `application/Api/`, código moderno PSR-4 em `src/` (`App\`), templates Smarty, JS vanilla/jQuery em `public/scripts/` e Sass em `frontend/scss/`. Banco PostgreSQL via `PDO_PGSQL`, com banco central e bancos de operador.
- **Go**: backend puro, arquitetura hexagonal conforme o `AGENTS.md` do projeto (ex.: `/var/www/GoOcppServer`). Domínio e aplicação isolados de protocolo, transporte e persistência. Configuração só na camada de plataforma, e `context.Context` propagado em todo I/O.

Trate toda entrada externa como hostil, todo segredo como sagrado e toda checagem de autorização como obrigatória. Segurança não é uma fase: é uma restrição sobre cada linha que toca dados de usuário, dinheiro, autenticação ou sistemas externos.

Leia antes o `AGENTS.md` do repositório. As regras dele (ex.: `checkPerm()`, CSRF no portal, "não registre `idTag`", "`os.Getenv` só na configuração") são a implementação concreta das regras abaixo naquele projeto e prevalecem sobre exemplos genéricos.

## Quando Usar

- Qualquer coisa que aceite input: formulário do portal, endpoint de API, mensagem OCPP, webhook, arquivo de cron com dados externos
- Implementar ou alterar autenticação, sessão, ACL (`checkPerm`) ou escopo de operador/cliente
- Armazenar ou transmitir dados sensíveis (cartão, credenciais de gateway, PII, tokens técnicos)
- Integrar com APIs externas (gateway de pagamento, adquirentes, ERP, S3)
- Adicionar uploads, downloads de arquivo, exportações ou callbacks
- Fluxos financeiros: venda, cancelamento, pré-autorização, saldo, início/parada de recarga

## Processo: Threat Model Primeiro

Controles aplicados sem threat model são chutes. Antes de endurecer, passe cinco minutos pensando como atacante:

1. **Mapeie as fronteiras de confiança.** Onde dados não confiáveis entram no sistema?
   - **PHP:** `$_GET`/`$_POST`/`$_COOKIE`/`$_FILES`, `$this->_request->getParam()` (que mistura rota, query e POST), headers (incluindo `X-Forwarded-For`), payloads JSON/criptografados das APIs, respostas de gateway/ERP, arquivos lidos por crons, planilhas importadas.
   - **Go:** o `chargePointID` da URL `/ocpp/{chargePointID}`, cada payload OCPP (`idTag`, `connectorId`, medições), futuros handlers REST/WebSocket, eventos de broker, variáveis de ambiente.
   - **Ambos:** saída de LLM e valores que *parecem* internos porque o SO os entregou (linha de comando de outro processo, nome de arquivo num volume compartilhado, path num payload de job). A confiança segue **quem escreveu** o valor, não o canal que o entregou. Cada fronteira é superfície de ataque.
2. **Nomeie os ativos.** O que vale a pena roubar ou quebrar? Credenciais, dados de cartão, chaves de gateway, saldo, transações, dados de outro operador, comandos remotos de carregador (`RemoteStart`/`RemoteStop`), ações administrativas.
3. **Aplique STRIDE em cada fronteira.** É uma lente rápida, não uma cerimônia:

| Ameaça | Pergunta | Mitigação típica (PHP / Go) |
|---|---|---|
| **S**poofing | Alguém consegue se passar por usuário, operador ou carregador? | `Zend_Auth` + regenerar sessão no login; APIs com assinatura/criptografia da base REST / security profile OCPP (Basic Auth sobre TLS ou mTLS) |
| **T**ampering | Dados podem ser alterados em trânsito ou em repouso? | Queries parametrizadas, HTTPS/TLS, verificação de assinatura, CSRF |
| **R**epudiation | Uma ação pode ser negada depois? | Log estruturado de eventos de segurança e financeiros (sem segredos) |
| **I**nformation disclosure | Dados podem vazar? | Allowlist de campos na resposta, erros genéricos, sem stack trace, sem `idTag`/token em log |
| **D**enial of service | Dá para sobrecarregar? | Rate limit, limite de tamanho de corpo/mensagem, timeouts, filas finitas |
| **E**levation of privilege | Um usuário ganha direitos que não deveria? | `checkPerm()` + escopo de operador/cliente em toda query; autorização por escopo nos casos de uso Go |

4. **Escreva casos de abuso ao lado dos casos de uso.** Para cada funcionalidade, pergunte "como eu abusaria disso?" e transforme a resposta no primeiro teste. Exemplos: um usuário do operador A lendo a venda do operador B só trocando o `id` da URL; um carregador enviando `StartTransaction` para um conector que não é seu.

Se você não consegue nomear as fronteiras de confiança de uma funcionalidade, ainda não está pronto para protegê-la. Isso é o OWASP **A04: Insecure Design**: a maioria das brechas nasce no design, não no código.

## O Sistema de Fronteira em Três Níveis

### Sempre Fazer (Sem Exceções)

- **Validar todo input externo** na fronteira (action do controller, handler da API, adapter OCPP) antes de chegar a service, repository ou domínio
- **Parametrizar todas as queries**: `Zend_Db_Select` com `?`/`quoteInto`, PDO com placeholders, `database/sql`/pgx com `$1`. Nunca concatenar input em SQL
- **Escapar a saída** conforme o contexto: Smarty `{$var|escape:'html'}` (ou `escape:'javascript'` dentro de JS), `.text()`/`textContent` no jQuery/JS
- **Checar autorização** em toda action e em todo recurso: `checkPerm()` + dono (operador/cliente) do registro
- **Validar CSRF** em toda operação mutável do portal
- **Usar HTTPS/TLS** em toda comunicação externa, sem desligar verificação de certificado (`verify => false` no Guzzle, `InsecureSkipVerify` no Go)
- **Hash de senha** com `password_hash()`/`password_verify()` (PHP) ou bcrypt/argon2 (Go)
- **Comparar segredos em tempo constante**: `hash_equals()` (PHP), `subtle.ConstantTimeCompare` (Go)
- **Gerar tokens com CSPRNG**: `random_bytes()` (PHP), `crypto/rand` (Go). Nunca `rand()`, `mt_rand()`, `uniqid()` ou `math/rand`
- **Rodar a auditoria nativa** contra o lockfile commitado antes de cada release: `composer audit`, `govulncheck ./...`, `npm audit` (build Sass)

### Perguntar Antes (Requer Aprovação Humana)

- Adicionar novos fluxos de autenticação ou mudar a lógica de auth, criptografia ou assinatura das APIs (em especial `AppV2`)
- Armazenar novas categorias de dado sensível (PII, dados de cartão, credenciais de gateway)
- Adicionar novas integrações com serviços externos
- Mudar CORS, headers de segurança ou configuração de sessão/cookie
- Adicionar handlers de upload
- Modificar rate limiting, filas ou limites de mensagem
- Conceder permissões elevadas, criar recursos/privilégios de ACL ou níveis de usuário
- Adicionar uma dependência (o `AGENTS.md` do Go exige necessidade comprovada e revisão)

### Nunca Fazer

- **Nunca commitar segredos** (senhas de banco, chaves de gateway, tokens), inclusive em `config.ini`/`vendpago.ini` versionados, fixtures, mocks Mockoon ou `.env`
- **Nunca logar dados sensíveis**: senhas, tokens, `TechnicalToken`, `idTag`, cartão completo, CVV, payloads completos de gateway
- **Nunca confiar em validação client-side** (jQuery Validate, `required` do HTML) como fronteira de segurança
- **Nunca desligar headers de segurança** ou a checagem de CSRF "só nesta tela"
- **Nunca usar `eval()`, `unserialize()` em input, `include`/`require` com path vindo do usuário, `extract($_POST)` ou variáveis variáveis (`$$nome`)**
- **Nunca usar `.html()`, `.append(string)`, `innerHTML` ou `$(stringDoUsuario)`** com dados do usuário ou de uma API
- **Nunca guardar token de autenticação em `localStorage`**
- **Nunca expor stack trace**, SQL ou mensagem interna ao usuário (`displayExceptions` desligado em produção; erros genéricos no Go)
- **Nunca comparar hash/token com `==`** em PHP (type juggling: `"0e123" == "0e456"` é `true`)

## Controles de Hardening

As regras abaixo são o fluxo de trabalho. Uma implementação concreta de cada uma, em PHP e Go, está em [references/hardening-patterns.md](references/hardening-patterns.md). Abra a seção de que precisar quando chegar àquele código, não antes.

### Injection, XSS e controle de acesso

- **SQL:** parametrize tudo. No Zend, `->where('id = ?', $id)`, `$db->quoteInto()`, `->where('id IN (?)', $ids)`. Identificadores (coluna de `ORDER BY`, direção, nome de tabela) não aceitam placeholder: use **allowlist**. Em Go, `db.QueryContext(ctx, "... WHERE id = $1", id)`, nunca `fmt.Sprintf`.
- **Comandos de sistema:** evite `exec`/`shell_exec`/`system`/crases. Se inevitável, `escapeshellarg()` em cada argumento. Em Go, `exec.CommandContext` com argumentos separados, nunca `sh -c` com input.
- **XSS:** todo `{$var}` em Smarty sai com `|escape:'html'` (atributo, texto) ou `|escape:'javascript'` (dentro de `<script>`). JSON embutido em HTML usa `json_encode($x, JSON_HEX_TAG | JSON_HEX_AMP | JSON_HEX_APOS | JSON_HEX_QUOT)`. No JS, `.text()`/`textContent`/`.val()`. HTML cru só depois de sanitizar com allowlist.
- **Autorização (A01, IDOR):** autenticação não basta. `checkPerm($recurso, $privilegio)` diz se o nível pode executar a ação. A query precisa garantir que o registro pertence ao operador/cliente do usuário logado. Em Go, o caso de uso valida escopo (quem pode comandar qual estação/conector) antes de qualquer efeito.

Padrões: [Injection](references/hardening-patterns.md#injection), [XSS](references/hardening-patterns.md#cross-site-scripting-xss), [Controle de acesso](references/hardening-patterns.md#controle-de-acesso-quebrado-idor).

### Autenticação, sessão e CSRF

- Senhas com `password_hash($senha, PASSWORD_DEFAULT)`. Hashes legados (`md5`, `sha1`) migram no próximo login com `password_verify` + `password_needs_rehash`. Em Go, `golang.org/x/crypto/bcrypt` (custo ≥ 12) ou argon2id.
- Cookie de sessão `httponly`, `secure` e `samesite=Lax` (ou `Strict`), com `session.use_strict_mode=1`. Chame `Zend_Session::regenerateId()` logo após autenticar (contra session fixation) e defina um tempo de expiração limitado.
- CSRF: use os helpers do projeto quando existirem (ex.: `isCsrfValidoNaRequisicao()` em `Henger_Controller_Action`, partial `csrf-token-field.tpl`, header `X-CSRF-Token` nos AJAX). Se o projeto não tiver helper, **pergunte antes** de criar um; não improvise por tela.
- APIs Go/PHP consumidas por máquina não usam cookie: autenticam por credencial/assinatura em cada requisição e validam expiração e escopo.

Padrão: [Autenticação e sessão](references/hardening-patterns.md#autenticação-sessão-e-csrf).

### Headers, CORS e respostas

- Headers de segurança em toda resposta HTML (no servidor web ou via `$this->getResponse()->setHeader()`). CSP começa em `default-src 'self'` e só aperta. Em telas legadas com muito `<script>` inline, comece por `Content-Security-Policy-Report-Only`.
- CORS restrito a uma lista explícita de origens vinda da configuração. Nunca `*` com credenciais. Em Go, middleware próprio com allowlist.
- Remova campos sensíveis (hash de senha, tokens, dados de cartão, chaves de gateway) antes de qualquer resposta. Monte DTOs/`RespostaJson` com allowlist em vez de devolver `$row->toArray()` ou a struct do domínio. Corpo de erro é genérico; detalhes vão para o log do servidor.

Padrões: [Configuração insegura](references/hardening-patterns.md#configuração-insegura), [Exposição de dados sensíveis](references/hardening-patterns.md#exposição-de-dados-sensíveis).

### Validação de input e uploads

- Valide na fronteira: formato, tamanho, faixa, enum. No PHP, valide antes de chamar o service e converta para tipo (`int`, DTO de `src/`). `ParametroInvalidoException` ou equivalente vira 422 com detalhes estruturados. Em Go, o adapter/handler valida transporte (tamanho, formato de `chargePointID`, JSON estrito) e a aplicação valida regra. Daí em diante, o código só usa o valor já tipado.
- Uploads: allowlist de MIME verificado com `finfo_file()` (não `$_FILES['type']`, que vem do cliente), limite de tamanho, nome gerado pelo servidor, armazenamento fora de `public/`, `move_uploaded_file()`. A extensão não prova nada.
- Nunca desserialize input com `unserialize()`: use `json_decode(..., true)` ou `unserialize($x, ['allowed_classes' => false])` quando o legado exigir.
- XML externo: não passe `LIBXML_NOENT`/`LIBXML_DTDLOAD` para dados não confiáveis (XXE).

Padrões: [Validação na fronteira](references/hardening-patterns.md#validação-na-fronteira), [Upload de arquivos](references/hardening-patterns.md#upload-de-arquivos).

### Requisições do servidor para URLs (SSRF)

Qualquer URL influenciada pelo usuário (webhook configurável, "importar de URL", callback de gateway configurado no portal, URL de servidor de operador) pode ser apontada para serviços internos. Faça allowlist de esquema e host, resolva **todos** os registros DNS e rejeite qualquer endereço privado ou reservado (loopback, link-local `169.254.169.254`, privado, unique-local, IPv4 e IPv6), e proíba redirects. No PHP (Guzzle), essa checagem tem uma lacuna TOCTOU de DNS rebinding: fixe o IP resolvido com `CURLOPT_RESOLVE`. Em Go, valide o IP **no momento da conexão** com `net.Dialer.Control`, o que fecha a lacuna.

Padrão: [SSRF](references/hardening-patterns.md#ssrf).

### Operações destrutivas em paths derivados

Um delete, move ou overwrite é tão seguro quanto o valor que nomeia o alvo, e a confiança segue quem *escreveu* esse valor, não o canal que o entregou. Crons que limpam diretórios de relatório, exportações temporárias ou arquivos de terminal são os casos típicos. Uma checagem de formato prova boa formação, não autorização. Antes da chamada, exija as três coisas: o alvo resolvido (`realpath()`/`filepath.EvalSymlinks`) está sob uma **raiz em allowlist**; está pelo menos um nível **abaixo** dessa raiz; e tem **evidência de propriedade lida antes da operação**. Em caso de recusa, registre o alvo rejeitado e pare. Nunca recorra a um path padrão mais amplo. Em Go 1.24+, prefira `os.Root`, que impede escapar da raiz inclusive via symlink.

Por que a checagem é mais fraca do que parece (marcador autoatestado, corrida entre checagem e uso): [Paths destrutivos](references/hardening-patterns.md#operações-destrutivas-em-paths-derivados). Código completo: `../../references/security-checklist.md`.

### Rate limiting

Limite a API de forma geral e os endpoints de autenticação de forma estrita (cerca de 10 tentativas a cada 15 minutos). PHP-FPM não tem memória compartilhada entre servidores: `Zend_Cache` com backend `File` ou APCu conta por servidor. Com mais de um servidor, use um store compartilhado (tabela PostgreSQL com upsert atômico ou Redis, se existir na infra). Em Go, um limiter em memória (`x/time/rate` por chave) vale por instância: com mais de uma réplica, o limite efetivo vira `max × instâncias`. No OCPP, limite também mensagens por carregador e o número de conexões.

Padrão: [Rate limiting](references/hardening-patterns.md#rate-limiting).

### Segredos

- **PHP:** credenciais vêm da configuração Zend/`Zend_Registry` e não podem ser fixadas em código novo, logs ou fixtures. Os `.ini` de configuração são versionados, então valores reais não entram neles: use um arquivo local não versionado ou variáveis de ambiente lidas no bootstrap.
- **Go:** segredos vêm do ambiente, lidos **somente** na camada de configuração/composição (`internal/platform/runtime`). `.env.example` é versionado com placeholders; `.env` real nunca.
- **Ambos:** chaves `*.pem`/`*.key` ficam fora do repositório. Faça grep no diff staged antes de commitar. **Um segredo que chegou ao remoto está comprometido no momento em que chegou: rotacione primeiro, depois limpe o histórico.**

Padrão: [Gestão de segredos](references/hardening-patterns.md#gestão-de-segredos).

### Dependências e supply chain

1. **Encontre a fronteira de instalação e o gerenciador.** PHP: `composer.json` + `composer.lock` na raiz (e `package.json` + `package-lock.json` para o build Sass). Go: `go.mod` + `go.sum`. Confirme que o CI usa o mesmo lockfile. Pare se houver lockfiles concorrentes.
2. **Bloqueie código de terceiros antes da primeira execução.** Composer não roda scripts de dependências, mas roda **plugins**: mantenha `config.allow-plugins` explícito (nunca `true` global) e faça o bootstrap com `composer install --no-plugins --no-scripts` quando o pacote for novo. npm: `npm ci --ignore-scripts` no primeiro install e aprovação mínima depois. Go não tem scripts de instalação, mas `go generate` e diretivas de ferramentas executam código: revise antes de rodar.
3. **Rode a auditoria nativa antes de cada release** e faça triagem de crítico/alto por **alcançabilidade**. O `govulncheck` já reporta se o símbolo vulnerável é chamado; no `composer audit` e `npm audit`, confira manualmente (dependência de runtime, dev ou só do build Sass?). Nunca aplique correção forçada automaticamente (`npm audit fix --force`, `composer update` sem restrição): pré-visualize, leia o changelog e teste cada upgrade. Documente cada adiamento com motivo e data de revisão.
4. **Auditorias só casam advisories conhecidos.** Elas não pegam pacote novo malicioso nem typosquatting. Também **não enxergam código vendorizado fora do gerenciador**: `library/` (Zend, Smarty, MPDF6, PHPExcel) e jQuery/plugins copiados em `public/scripts/`. Mantenha o inventário de versões desses arquivos e verifique advisories manualmente. PHPExcel, por exemplo, está abandonado. Em Go, `go mod verify` confere os módulos contra o `go.sum`, e o checksum database (`sum.golang.org`) não deve ser desligado para módulos públicos (A06).

Árvore de triagem: [Triagem de auditoria](references/hardening-patterns.md#triagem-de-auditoria-de-dependências). Comandos por ecossistema: `../../references/security-checklist.md`.

### Dados pessoais e privacidade (LGPD)

Hardening pergunta "um atacante consegue ler isso?". Privacidade pergunta "*nós* deveríamos guardar isso, e por quanto tempo?". O dado mais barato de proteger, de vazar e de estar em conformidade é o que você nunca coletou: trate dado pessoal como passivo a minimizar.

- **Classifique os campos ao adicioná-los** (não pessoal, PII, sensível) e trate cada classe de acordo. CPF, e-mail, telefone e localização de terminal são PII; dados de cartão estão sob PCI DSS: nunca guarde PAN completo, CVV ou trilha.
- **Colete só com propósito declarado.** "Pode ser útil depois" é escopo latente de vazamento, não propósito. Mantenha PII fora de logs e telemetria.
- **Defina retenção antes e delete de fato.** Todo armazenamento de dado pessoal precisa de um prazo e de um caminho de deleção que funcione, incluindo o banco do operador, backups, cache (`Zend_Cache`), exportações em S3 e relatórios enviados.
- **Suporte os direitos do titular exigidos pela LGPD:** acesso, correção, eliminação, portabilidade. Desenhe o schema para que os dados de uma pessoa sejam encontráveis nos bancos central e de operador.
- **Compartilhar PII com terceiros** (ERP externo, gateway, analytics, fornecedor de LLM) exige base legal e contrato de tratamento.

Tabela de classificação: [Classificação de dados](references/hardening-patterns.md#classificação-de-dados).

### Funcionalidades com IA / LLM

Chamar um LLM (chatbot, resumo, agente, RAG) adiciona uma nova superfície de ataque. Mapeie-a no [OWASP Top 10 for LLM Applications (2025)](https://genai.owasp.org/llm-top-10/):

- **A saída do modelo é input não confiável** (LLM05). Nunca vai para `eval`, SQL, shell, `.html()` ou path de arquivo. Faça o parse defensivo, valide contra um schema e depois escape.
- **Prompts podem ser sequestrados** (LLM01). Texto não confiável no contexto (mensagem do usuário, página buscada, PDF) pode carregar instruções. O system prompt não é fronteira de segurança: permissões são impostas no código.
- **Mantenha segredos, dados de outros operadores e o system prompt completo fora da janela de contexto** (LLM02, LLM07). Limite o escopo das ferramentas, valide cada argumento e confirme ações destrutivas (LLM06). Limite tokens, taxa e profundidade de recursão (LLM10).

Padrão: [Saída de LLM](references/hardening-patterns.md#saída-de-llm).

## Checklist de Revisão

Antes de dar o aval, percorra `../../references/security-checklist.md`. Ele cobre threat model, pré-commit, autenticação, autorização, input, proteção de dados e privacidade, headers e CORS, dependências e supply chain, IA/LLM e tratamento de erros, com seções específicas de PHP e Go e as tabelas de referência rápida do OWASP.

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "É só o portal interno, segurança não importa" | Ferramentas internas são comprometidas e o portal movimenta dinheiro de operadores. O atacante mira o elo mais fraco. |
| "É legado, sempre foi assim" | Código legado é onde mais se acha concatenação de SQL e saída sem escape. Toque o arquivo, corrija a linha que você tocou. |
| "Depois a gente adiciona segurança" | Retrofit de segurança é 10x mais difícil. Adicione agora. |
| "Ninguém vai tentar explorar isso" | Scanners automáticos vão achar. Segurança por obscuridade não é segurança. |
| "O `checkPerm()` já protege" | Ele diz se o *nível* pode executar a ação, não se o *registro* pertence ao operador do usuário. Isso é IDOR. |
| "O Smarty/Zend já escapa" | Não por padrão neste setup: sem o modificador `escape` o valor sai cru. Framework dá ferramentas, não garantias. |
| "O carregador é nosso, confiamos nele" | O `chargePointID` na URL é autodeclarado. Sem security profile OCPP, qualquer cliente WebSocket se passa por carregador. |
| "É só um protótipo" | Protótipos viram produção. Hábitos de segurança desde o primeiro dia. |
| "Threat model é exagero aqui" | Cinco minutos de "como eu atacaria isso?" evitam falhas de design que nenhum controle corrige depois. |
| "É só saída do LLM, é só texto" | Esse "texto" pode ser SQL, uma tag `<script>` ou um comando de shell. Trate como qualquer input não confiável. |
| "O `composer audit` passou, a dependência é segura" | Auditorias casam advisories conhecidos. Não detectam pacote novo malicioso nem enxergam o que está vendorizado em `library/`. |
| "Coleta agora, talvez precise depois" | Dado que você não guarda não pode vazar, ser requisitado judicialmente ou ser mal deletado. |
| "LGPD é problema do jurídico" | Exportação, eliminação, retenção e consentimento são schema e código. O jurídico não consegue encaixar isso depois. |

## Sinais de Alerta

- Input do usuário concatenado em SQL (`"... WHERE id = " . $id`, `->where("id = $id")`, `fmt.Sprintf` em query), em comando de shell ou em HTML
- `->order($this->_getParam('ordem'))` sem allowlist
- `{$var}` em template Smarty sem `|escape`, ou `.html(resposta.mensagem)` no jQuery
- Action mutável do portal sem validação de CSRF, ou action sem `checkPerm()`
- Query que busca por `id` sem filtrar pelo operador/cliente do usuário logado
- `unserialize($_POST[...])`, `include $_GET[...]`, `extract($_REQUEST)`, `eval`
- Comparação de token/hash com `==`, ou token gerado com `rand()`/`uniqid()`/`md5(time())`
- Delete, move ou overwrite cujo alvo vem de um payload, de um valor de configuração ou da linha de comando de outro processo, protegido só por checagem de formato do path
- Segredos no código-fonte, em `.ini` versionado, em fixture ou no histórico
- `verify => false` no Guzzle ou `InsecureSkipVerify: true` no Go
- Endpoints de API sem autenticação ou autorização; CORS com `*`
- Sem rate limiting nos endpoints de login, ou limiter em memória na frente de mais de um servidor/réplica
- Stack traces ou erros internos expostos (`displayExceptions = 1` em produção, `err.Error()` direto no corpo HTTP)
- `idTag`, `TechnicalToken`, senha ou payload de gateway em log
- `http.Server` Go sem `ReadHeaderTimeout`, corpo sem `http.MaxBytesReader`, WebSocket sem limite de tamanho de mensagem
- Dependências com vulnerabilidades conhecidas alcançáveis, `allow-plugins: true` global ou lockfile não commitado
- Servidor buscando URL fornecida pelo usuário sem allowlist (SSRF)
- Saída de LLM passada para query, DOM, shell ou `eval`
- Dados pessoais coletados sem propósito, sem prazo de retenção ou sem caminho de deleção

## Verificação

Depois de implementar código relevante para segurança:

- [ ] `composer audit` / `govulncheck ./...` / `npm audit` sem achados crítico/alto alcançáveis e não mitigados; lockfiles commitados
- [ ] Nenhum segredo no código, nos `.ini` versionados ou no histórico do git
- [ ] Todo input validado nas fronteiras e convertido para tipo antes de seguir
- [ ] Toda query com valor externo parametrizada; identificadores dinâmicos por allowlist
- [ ] Toda saída em template/JS escapada conforme o contexto
- [ ] `checkPerm()` (ou escopo no caso de uso Go) e dono do registro checados em cada ação protegida
- [ ] CSRF validado em toda action mutável do portal
- [ ] Operações destrutivas no filesystem resolvem symlinks e verificam raiz permitida, profundidade mínima e propriedade antes de rodar
- [ ] Headers de segurança presentes na resposta (confira com o DevTools; veja a skill `browser-testing-with-devtools`)
- [ ] Respostas de erro não expõem detalhes internos
- [ ] Rate limiting ativo nos endpoints de auth, com store compartilhado quando há mais de um servidor/réplica
- [ ] Requisições do servidor para URLs externas validadas contra allowlist (sem SSRF)
- [ ] Logs estruturados sem dados sensíveis
- [ ] Testes de abuso (IDOR, CSRF ausente, input malformado, payload gigante) existem e passam: `composer test` / `make ci`
- [ ] Dados pessoais classificados, minimizados a um propósito declarado e com prazo de retenção
