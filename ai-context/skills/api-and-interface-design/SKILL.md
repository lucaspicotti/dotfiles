---
name: api-and-interface-design
description: "Orienta o design de APIs e interfaces estáveis. Use ao projetar APIs, limites de módulos ou qualquer interface pública. Use ao criar endpoints REST ou GraphQL, definir contratos de tipo entre módulos (PHP ou Go), ou estabelecer fronteiras entre frontend e backend."
disable-model-invocation: true
---

# Design de APIs e Interfaces

## Visão Geral

Projete interfaces estáveis, bem documentadas e difíceis de usar de forma incorreta. Boas interfaces tornam o caminho certo fácil e o caminho errado difícil. Isso se aplica a APIs REST, schemas GraphQL, limites de módulos, contratos de interface em PHP e Go, e qualquer superfície onde um trecho de código conversa com outro.

## Quando Usar

- Ao projetar novos endpoints de API
- Ao definir limites ou contratos de módulo entre equipes
- Ao criar interfaces/contratos entre camadas (controller/service/repository)
- Ao estabelecer o schema de banco de dados que influencia o formato da API
- Ao alterar interfaces públicas existentes

## Princípios Fundamentais

### Lei de Hyrum

> Com um número suficiente de usuários de uma API, todos os comportamentos observáveis do seu sistema serão dependidos por alguém, independentemente do que for prometido no contrato.

Isso significa: todo comportamento público — incluindo peculiaridades não documentadas, texto de mensagens de erro, timing e ordenação — se torna um contrato de fato assim que alguém passa a depender dele. Implicações de design:

- **Seja intencional sobre o que você expõe.** Todo comportamento observável é um possível compromisso.
- **Não vaze detalhes de implementação.** Se os usuários conseguem observar, eles vão depender disso.
- **Planeje a depreciação desde o design.** Veja `deprecation-and-migration` para como remover com segurança coisas das quais os usuários dependem.
- **Testes não são suficientes.** Mesmo com testes de contrato perfeitos, a Lei de Hyrum implica que mudanças "seguras" podem quebrar usuários reais que dependem de comportamento não documentado.

### A Regra da Versão Única

Evite forçar consumidores a escolher entre múltiplas versões da mesma dependência ou API. Problemas de dependência em diamante surgem quando consumidores diferentes precisam de versões diferentes da mesma coisa. Projete para um mundo em que apenas uma versão existe por vez — estenda em vez de bifurcar (fork).

### 1. Contrato Primeiro

Defina a interface antes de implementá-la. O contrato é a especificação — a implementação vem depois.

**PHP:**

```php
interface TaskRepository
{
    // Cria uma tarefa e retorna a tarefa criada com os campos gerados pelo servidor
    public function create(CreateTaskInput $input): Task;

    // Retorna tarefas paginadas que casam com os filtros
    public function list(ListTasksParams $params): PaginatedResult;

    // Retorna uma única tarefa ou lança TaskNotFoundException
    public function find(string $id): Task;

    // Atualização parcial — apenas os campos informados mudam
    public function update(string $id, UpdateTaskInput $input): Task;

    // Remoção idempotente — funciona mesmo se já removida
    public function delete(string $id): void;
}
```

**Go:**

```go
type TaskRepository interface {
    // Cria uma tarefa e retorna a tarefa criada com os campos gerados pelo servidor
    Create(ctx context.Context, input CreateTaskInput) (Task, error)

    // Retorna tarefas paginadas que casam com os filtros
    List(ctx context.Context, params ListTasksParams) (PaginatedResult, error)

    // Retorna uma única tarefa ou ErrTaskNotFound
    Find(ctx context.Context, id string) (Task, error)

    // Atualização parcial — apenas os campos informados mudam
    Update(ctx context.Context, id string, input UpdateTaskInput) (Task, error)

    // Remoção idempotente — funciona mesmo se já removida
    Delete(ctx context.Context, id string) error
}
```

Em Go, quem define a interface é normalmente o **consumidor** (o pacote que usa `TaskRepository`), não quem a implementa — veja "Aceite Interfaces, Retorne Structs" mais adiante.

### 2. Semântica de Erros Consistente

Escolha uma estratégia de erro e use-a em todos os lugares:

```
// REST: código de status HTTP + corpo de erro estruturado
// Toda resposta de erro segue o mesmo formato
{
  "error": {
    "code": "VALIDATION_ERROR",   // legível por máquina
    "message": "O e-mail é obrigatório", // legível por humano
    "details": { }                 // contexto adicional quando útil
  }
}

// Mapeamento de código de status
// 400 → Cliente enviou dados inválidos
// 401 → Não autenticado
// 403 → Autenticado, mas não autorizado
// 404 → Recurso não encontrado
// 409 → Conflito (duplicidade, divergência de versão)
// 422 → Falha de validação (semanticamente inválido)
// 500 → Erro de servidor (nunca exponha detalhes internos)
```

**PHP:**

```php
final class ApiError extends \Exception
{
    public function __construct(
        private readonly string $errorCode,
        string $message,
        private readonly ?array $details = null,
    ) {
        parent::__construct($message);
    }

    public function toArray(): array
    {
        return [
            'error' => [
                'code' => $this->errorCode,
                'message' => $this->getMessage(),
                'details' => $this->details,
            ],
        ];
    }
}

// Handler global de exceções converte ApiError em resposta JSON + status HTTP
```

**Go:**

```go
type APIError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details any    `json:"details,omitempty"`
}

func writeError(w http.ResponseWriter, status int, code, message string, details any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]APIError{
        "error": {Code: code, Message: message, Details: details},
    })
}
```

**Não misture padrões.** Se alguns endpoints lançam exceção, outros retornam `null`/`nil` e outros retornam `{ error }` — quem consome o código não consegue prever o comportamento.

### 3. Valide nas Fronteiras

Confie no código interno. Valide nas bordas do sistema, onde entra input externo:

**PHP:**

```php
// Validação na fronteira da API (controller)
public function store(Request $request): JsonResponse
{
    $validated = $this->validator->validate($request->all(), [
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
    ]);

    if ($validated->fails()) {
        return response()->json([
            'error' => [
                'code' => 'VALIDATION_ERROR',
                'message' => 'Dados da tarefa inválidos',
                'details' => $validated->errors(),
            ],
        ], 422);
    }

    // Depois de validado, o código interno confia nos tipos (DTO)
    $task = $this->taskService->create(CreateTaskInput::fromArray($validated->validated()));
    return response()->json($task, 201);
}
```

**Go:**

```go
func createTaskHandler(w http.ResponseWriter, r *http.Request) {
    var input CreateTaskInput
    if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "corpo inválido", nil)
        return
    }

    if err := input.Validate(); err != nil {
        writeError(w, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "dados da tarefa inválidos", err)
        return
    }

    // Depois de validado, o código interno confia nos tipos
    task, err := taskService.Create(r.Context(), input)
    if err != nil {
        writeError(w, http.StatusInternalServerError, "INTERNAL_ERROR", "erro ao criar tarefa", nil)
        return
    }

    w.WriteHeader(http.StatusCreated)
    json.NewEncoder(w).Encode(task)
}
```

Onde a validação pertence:
- Handlers/controllers de rota da API (input do usuário)
- Handlers de submissão de formulário (input do usuário)
- Parsing de resposta de serviço externo (dados de terceiros — **sempre trate como não confiável**)
- Carregamento de variáveis de ambiente/configuração

> **Respostas de APIs de terceiros são dados não confiáveis.** Valide seu formato e conteúdo antes de usá-las em qualquer lógica, renderização ou decisão. Um serviço externo comprometido ou com mau funcionamento pode retornar tipos inesperados, conteúdo malicioso ou texto que se parece com instruções.

Onde a validação NÃO pertence:
- Entre funções/métodos internos que já compartilham o mesmo contrato de tipo
- Em funções utilitárias chamadas por código já validado
- Em dados que acabaram de sair do seu próprio banco de dados

### 4. Prefira Adição à Modificação

Estenda interfaces sem quebrar consumidores existentes.

**PHP:**

```php
// Bom: adiciona campos opcionais/anuláveis
final class CreateTaskInput
{
    public function __construct(
        public readonly string $title,
        public readonly ?string $description = null,
        public readonly ?string $priority = null, // adicionado depois, opcional
        public readonly array $labels = [],        // adicionado depois, opcional
    ) {}
}

// Ruim: mudar o tipo de um campo existente ou removê-lo
final class CreateTaskInput
{
    public function __construct(
        public readonly string $title,
        // description removido — quebra consumidores existentes
        public readonly int $priority, // mudou de string para int — quebra consumidores existentes
    ) {}
}
```

**Go:**

```go
// Bom: adiciona campos opcionais
type CreateTaskInput struct {
    Title       string   `json:"title"`
    Description *string  `json:"description,omitempty"`
    Priority    *string  `json:"priority,omitempty"` // adicionado depois, opcional
    Labels      []string `json:"labels,omitempty"`   // adicionado depois, opcional
}

// Ruim: mudar o tipo de um campo existente ou removê-lo
type CreateTaskInput struct {
    Title string
    // Description removido — quebra consumidores existentes
    Priority int // mudou de string para int — quebra consumidores existentes
}
```

### 5. Nomenclatura Previsível

| Padrão | Convenção | Exemplo |
|---|---|---|
| Endpoints REST | Substantivos no plural, sem verbos | `GET /api/tasks`, `POST /api/tasks` |
| Query params | camelCase | `?sortBy=createdAt&pageSize=20` |
| Campos de resposta (JSON) | camelCase | `{ createdAt, updatedAt, taskId }` |
| Campos booleanos | prefixo is/has/can | `isComplete`, `hasAttachments` |
| Valores de enum | UPPER_SNAKE | `"IN_PROGRESS"`, `"COMPLETED"` |

Isso vale para o payload JSON trafegado, independentemente da linguagem do backend. Internamente, siga a convenção idiomática de cada linguagem — em PHP, `camelCase` para propriedades e métodos, `PascalCase` para classes; em Go, `PascalCase` para identificadores exportados e tags `json:"camelCase"` nas structs para manter o payload consistente.

### 6. Honrando uma Chave de Idempotência

Aceitar um header `Idempotency-Key` é o contrato. Honrá-lo é a implementação, e é aí que o dinheiro se perde — uma chave que o servidor aceita mas trata de forma descuidada é pior do que nenhuma chave, porque agora o cliente acredita que repetir a requisição é seguro.

**Derive a chave da intenção, não da tentativa.** A chave deve ser estável entre retentativas de uma mesma intenção e diferente entre intenções distintas:

```
uuid_aleatório()                        // ✗ nova chave a cada tentativa — cada retry é uma nova cobrança
"{userId}:{amount}"                     // ✗ duas cobranças legítimas de R$50 colapsam em uma só
"{orderId}:{timestamp_atual}"           // ✗ um timestamp é um uuid aleatório disfarçado

request.headers['idempotency-key']      // ✓ o cliente gera uma vez, reutiliza no retry
"charge:v1:{orderId}"                   // ✓ derivada de um identificador imutável
```

A chave vem do cliente ou do evento que iniciou a operação — nunca da camada que está fazendo a retentativa.

**Reivindique a chave de forma atômica. Uma verificação seguida de uma ação é uma corrida (race condition):**

**PHP:**

```php
// ✗ TOCTOU: duas retentativas concorrentes leem "não visto" e cobram duas vezes
if (!$repository->exists($key)) {
    $this->chargeCard($amount);
    $repository->insert($key);
}

// ✓ deixe a constraint de unicidade decidir o vencedor
try {
    $repository->insert(['key' => $key, 'state' => 'in_progress', 'request_hash' => $hash]);
} catch (UniqueConstraintViolationException) {
    return $this->replayOrReject($key);
}

$result = $this->chargeCard($amount);
$repository->update($key, ['state' => 'succeeded', 'response' => $result]);
```

**Go:**

```go
// ✗ TOCTOU: duas retentativas concorrentes leem "não visto" e cobram duas vezes
exists, _ := repo.Exists(ctx, key)
if !exists {
    chargeCard(amount)
    repo.Insert(ctx, key)
}

// ✓ deixe a constraint de unicidade decidir o vencedor
err := repo.Insert(ctx, IdempotencyRecord{Key: key, State: "in_progress", RequestHash: hash})
if isUniqueViolation(err) {
    return replayOrReject(ctx, key)
} else if err != nil {
    return err
}

result, err := chargeCard(amount)
if err != nil {
    return err
}
repo.Update(ctx, key, "succeeded", result)
```

A constraint de unicidade *é* o mecanismo. Um repositório que não consegue garantir unicidade em uma única operação não sustenta isso.

**Proteja o payload.** A mesma chave com um corpo diferente é um bug do cliente e deve falhar de forma explícita, em vez de servir a primeira resposta para uma segunda requisição:

```
se registro_existente.request_hash != hash(corpo_da_requisicao):
    retornar 422 "chave de idempotência reutilizada com payload diferente"
```

**Decida o que uma duplicata em andamento recebe.** A primeira requisição ainda está rodando quando a segunda chega — o caso comum sob tempestades de retry:

| Estratégia | Resposta | Quando usar |
|---|---|---|
| Rejeitar | `409 Conflict` | Cliente pode tentar de novo depois; mais simples e seguro |
| Esperar | Bloqueia pelo resultado, com limite de tempo | O chamador precisa do resultado de forma síncrona |
| Retornar pendente | `202` + URL de status | Efeitos de longa duração |

Nunca deixe o segundo chamador passar porque a primeira tentativa "parece travada". Uma tentativa travada cujo destino é desconhecido é exatamente o momento em que duplicar custa mais caro.

**Toda chamada tem três resultados possíveis, não dois: sucesso, falha e _desconhecido_.** Um timeout não diz nada sobre se o efeito foi aplicado. Registre a intenção *antes* de fazer a chamada externa, para que uma falha entre a chamada e a resposta deixe evidência de que algo precisa ser resolvido depois — em vez de uma cobrança repetida silenciosamente.

**Defina a retenção a partir da cadeia de retry mais longa**, não do custo de disco. As chaves precisam sobreviver a todo caminho que possa reentregar a mesma intenção, incluindo uma fila de dead-letter reprocessada uma semana depois e qualquer janela de disputa do provedor de pagamento. Um TTL de chave de 24 horas atrás de uma DLQ de 7 dias é uma duplicata esperando para acontecer.

## Padrões de API REST

### Design de Recursos

```
GET    /api/tasks              → Lista tarefas (com query params para filtro)
POST   /api/tasks              → Cria uma tarefa
GET    /api/tasks/:id          → Busca uma única tarefa
PATCH  /api/tasks/:id          → Atualiza uma tarefa (parcial)
DELETE /api/tasks/:id          → Remove uma tarefa

GET    /api/tasks/:id/comments → Lista comentários de uma tarefa (sub-recurso)
POST   /api/tasks/:id/comments → Adiciona um comentário a uma tarefa
```

### Paginação

Pagine endpoints de listagem:

```
// Requisição
GET /api/tasks?page=1&pageSize=20&sortBy=createdAt&sortOrder=desc

// Resposta
{
  "data": [...],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 142,
    "totalPages": 8
  }
}
```

### Filtragem

Use query params para filtros:

```
GET /api/tasks?status=in_progress&assignee=user123&createdAfter=2025-01-01
```

### Atualizações Parciais (PATCH)

Aceite objetos parciais — atualize apenas o que foi informado:

```
// Apenas o título muda, o resto é preservado
PATCH /api/tasks/123
{ "title": "Título atualizado" }
```

## Padrões de Interface em PHP

### Defina o contrato com `interface`

Todos os métodos de uma interface são implicitamente públicos e abstratos — a interface descreve **o quê**, nunca **o como**:

```php
interface Notifier
{
    public function send(string $recipient, string $message): void;
}
```

### Implemente com `implements`

Uma classe pode implementar várias interfaces, separadas por vírgula. Se não implementar todos os métodos exigidos, é erro fatal:

```php
class EmailNotifier implements Notifier
{
    public function send(string $recipient, string $message): void
    {
        // ...
    }
}

class Task extends Entity implements Serializable, Comparable
{
    // precisa implementar os métodos de ambas as interfaces
}
```

### Constantes de interface

Interfaces podem declarar constantes, herdadas por quem as implementa:

```php
interface HttpStatus
{
    const OK = 200;
    const NOT_FOUND = 404;
}

class ApiResponse implements HttpStatus
{
    public function ok(): int
    {
        return self::OK; // 200
    }
}
```

### Herança entre interfaces (`extends`, inclusive múltipla)

Interfaces podem estender uma ou várias outras interfaces, compondo contratos maiores:

```php
interface Readable
{
    public function read(): string;
}

interface Writable
{
    public function write(string $data): void;
}

interface ReadWritable extends Readable, Writable
{
}
```

### Separação Input/Output com DTOs imutáveis

```php
// Input: o que o chamador fornece
final class CreateTaskInput
{
    public function __construct(
        public readonly string $title,
        public readonly ?string $description = null,
    ) {}
}

// Output: o que o sistema retorna (inclui campos gerados pelo servidor)
final class Task
{
    public function __construct(
        public readonly string $id,
        public readonly string $title,
        public readonly ?string $description,
        public readonly \DateTimeImmutable $createdAt,
        public readonly \DateTimeImmutable $updatedAt,
        public readonly string $createdBy,
    ) {}
}
```

### Enums para variantes com segurança de tipo (PHP 8.1+)

Onde outras linguagens usariam union types discriminadas, PHP usa enums (possivelmente backed) mais um value object para os dados de cada variante:

```php
enum TaskStatus: string
{
    case Pending = 'pending';
    case InProgress = 'in_progress';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}

function statusLabel(TaskStatus $status): string
{
    return match ($status) {
        TaskStatus::Pending => 'Pendente',
        TaskStatus::InProgress => 'Em andamento',
        TaskStatus::Completed => 'Concluída',
        TaskStatus::Cancelled => 'Cancelada',
    };
}
```

### IDs como Value Objects (equivalente a "branded types")

```php
final class TaskId
{
    public function __construct(private readonly string $value) {}

    public function toString(): string
    {
        return $this->value;
    }
}

final class UserId
{
    public function __construct(private readonly string $value) {}
}

// Evita passar um UserId onde um TaskId é esperado — erro de tipo em tempo de compilação/análise estática
function getTask(TaskId $id): Task { /* ... */ }
```

### Boas práticas específicas de PHP

- **Não use construtores em interfaces** — reduz a flexibilidade e pode gerar comportamento inconsistente entre implementações.
- **Use os mesmos nomes de parâmetro** entre a interface e a implementação, especialmente relevante com argumentos nomeados (PHP 8.0+).
- Ao implementar múltiplas interfaces com métodos de mesmo nome, garanta assinaturas compatíveis (covariância de retorno, contravariância de parâmetros).
- Use `instanceof` junto com a declaração de tipo para checar conformidade com uma interface em tempo de execução, quando necessário.

## Padrões de Interface em Go

### Implementação implícita

Um tipo satisfaz uma interface automaticamente ao implementar todos os métodos exigidos — sem `implements` explícito. Isso permite que tipos já existentes passem a satisfazer interfaces criadas depois:

```go
type Notifier interface {
    Send(recipient, message string) error
}

type EmailNotifier struct{}

// EmailNotifier satisfaz Notifier automaticamente
func (n EmailNotifier) Send(recipient, message string) error {
    // ...
    return nil
}
```

### Aceite interfaces, retorne structs

```go
// Bom: flexível — funciona com arquivos, buffers, conexões de rede
func Save(w io.Writer, data []byte) error

// Ruim: rígido — funciona apenas com arquivos
func Save(f *os.File, data []byte) error
```

### Interfaces pequenas e focadas

Interfaces em Go são mais úteis quando têm de 1 a 3 métodos — `io.Reader`, `fmt.Stringer` e `error` têm um único método cada. Prefira compor várias interfaces pequenas a definir uma grande.

### Quem consome define a interface

Em Go, a interface costuma ser declarada no pacote que a consome, não no pacote que a implementa. Isso permite que implementações existam sem conhecer seus consumidores, e facilita criar mocks/fakes em testes:

```go
// No pacote do serviço (consumidor)
type TaskRepository interface {
    FindByID(ctx context.Context, id string) (Task, error)
    Create(ctx context.Context, t Task) error
}

type mockRepo struct{ /* implementação fake */ }

func TestService(t *testing.T) {
    svc := NewService(&mockRepo{})
    // testar sem dependências reais
}
```

### Composição de interfaces

Interfaces podem embutir outras, combinando comportamentos:

```go
type ReadWriter interface {
    io.Reader
    io.Writer
}
```

### Type switch para variantes (equivalente a union discriminada)

```go
type TaskStatus interface{ isTaskStatus() }

type Pending struct{}
type InProgress struct{ Assignee string; StartedAt time.Time }
type Completed struct{ CompletedAt time.Time; CompletedBy string }
type Cancelled struct{ Reason string }

func (Pending) isTaskStatus()     {}
func (InProgress) isTaskStatus()  {}
func (Completed) isTaskStatus()   {}
func (Cancelled) isTaskStatus()   {}

func statusLabel(s TaskStatus) string {
    switch v := s.(type) {
    case Pending:
        return "Pendente"
    case InProgress:
        return fmt.Sprintf("Em andamento (%s)", v.Assignee)
    case Completed:
        return fmt.Sprintf("Concluída em %s", v.CompletedAt)
    case Cancelled:
        return fmt.Sprintf("Cancelada: %s", v.Reason)
    }
    return ""
}
```

### Tipos nomeados para IDs (equivalente a "branded types")

```go
type TaskID string
type UserID string

// Evita passar um UserID onde um TaskID é esperado
func GetTask(id TaskID) (Task, error) { /* ... */ }
```

### Cuidado com value receiver vs. pointer receiver

Se algum método da interface for implementado com pointer receiver, apenas o ponteiro satisfaz a interface — o valor por si só, não:

```go
type Incrementable interface {
    Increment()
}

func (c *Counter) Increment() { c.value++ } // pointer receiver

var i Incrementable = &Counter{} // ✓ funciona
var i Incrementable = Counter{}  // ✗ erro de compilação
```

## Racionalizações Comuns

| Racionalização | Realidade |
|---|---|
| "Vamos documentar a API depois" | Os tipos/contratos SÃO a documentação. Defina-os primeiro. |
| "Não precisamos de paginação por enquanto" | Você vai precisar assim que alguém tiver 100+ itens. Adicione desde o início. |
| "PATCH é complicado, vamos usar só PUT" | PUT exige o objeto completo a cada vez. PATCH é o que os clientes realmente querem. |
| "Vamos versionar a API quando for preciso" | Mudanças que quebram compatibilidade sem versionamento quebram consumidores. Projete para extensão desde o início. |
| "Ninguém usa esse comportamento não documentado" | Lei de Hyrum: se é observável, alguém depende disso. Trate todo comportamento público como um compromisso. |
| "Podemos simplesmente manter duas versões" | Múltiplas versões multiplicam o custo de manutenção e criam problemas de dependência em diamante. Prefira a Regra da Versão Única. |
| "APIs internas não precisam de contrato" | Consumidores internos também são consumidores. Contratos evitam acoplamento e permitem trabalho em paralelo. |
| "Aceitar o header Idempotency-Key já é suficiente" | O header é o contrato; persistir a chave junto ao resultado é a implementação. Uma chave aceita mas não honrada diz ao cliente que repetir é seguro quando não é. |
| "Nossa fila garante entrega exactly-once" | Nenhuma fila garante isso diante de uma falha do consumidor — o ack do broker e o efeito colateral não estão na mesma transação. Projete para at-least-once com processamento idempotente. |
| "Requisições duplicadas são raras" | Elas são *correlacionadas*. Retentativas disparam justamente quando uma dependência está degradada — o momento em que duplicatas são mais prováveis e mais caras. |

## Sinais de Alerta

- Endpoints que retornam formatos diferentes dependendo da condição
- Formatos de erro inconsistentes entre endpoints
- Validação espalhada pelo código interno em vez de concentrada nas fronteiras
- Mudanças que quebram compatibilidade em campos existentes (mudança de tipo, remoção)
- Endpoints de listagem sem paginação
- Verbos em URLs REST (`/api/createTask`, `/api/getUsers`)
- Respostas de API de terceiros usadas sem validação ou sanitização
- Um `SELECT`/`exists` de chave de idempotência seguido de um `INSERT` — isso é uma corrida (race condition), não uma proteção
- Uma chave de idempotência derivada de um UUID, timestamp, ou qualquer coisa regenerada a cada tentativa
- A mesma chave aceita com um corpo de requisição diferente, retornando silenciosamente a primeira resposta
- Uma janela de retenção de chave menor que o caminho de reentrega mais longo possível
- Em PHP: interfaces com construtor, ou implementações com assinatura de método incompatível com a interface
- Em Go: interfaces grandes (muitos métodos) definidas pelo pacote que implementa, em vez de pelo pacote que consome

## Verificação

Depois de projetar uma API:

- [ ] Todo endpoint tem schemas de input e output tipados (DTOs em PHP, structs em Go)
- [ ] Respostas de erro seguem um único formato consistente
- [ ] A validação acontece apenas nas fronteiras do sistema
- [ ] Endpoints de listagem suportam paginação
- [ ] Novos campos são aditivos e opcionais (compatíveis com versões anteriores)
- [ ] A nomenclatura segue convenções consistentes em todos os endpoints
- [ ] A documentação da API ou os contratos (interfaces/DTOs/structs) são versionados junto com a implementação
- [ ] Endpoints que alteram estado honram uma chave de idempotência ou estão documentados como inseguros para retry
- [ ] A chave é reivindicada em uma operação atômica, protegida por uma constraint de unicidade
- [ ] Uma chave reutilizada com payload diferente falha de forma explícita em vez de repetir a resposta errada
- [ ] A resposta para uma duplicata em andamento é uma escolha deliberada (409, espera, ou 202), não algo que "aconteceu"
- [ ] A retenção da chave sobrevive ao caminho de retry mais longo, incluindo reprocessamento de dead-letter
