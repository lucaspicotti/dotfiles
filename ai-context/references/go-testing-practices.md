# Boas práticas de testes em Go

Referência operacional para skills de IA que criam, alteram ou revisam testes Go.

Baseada em:
- [Strategies for Writing More Effective Tests in Golang](https://dev.to/litmus-chaos/strategies-for-writing-more-effective-tests-in-golang-1fma) (Litmus Chaos, dev.to), consultado em 20 de setembro de 2026.
- [A Comprehensive Guide to Testing in Go](https://blog.jetbrains.com/go/2022/11/22/comprehensive-guide-to-testing-in-go/) (JetBrains Go Blog), consultado em 20 de setembro de 2026.
- [Learn Go with Tests](https://quii.gitbook.io/learn-go-with-tests), especialmente os capítulos de mocking, injeção de dependência e o apêndice de antipadrões, consultado em 20 de setembro de 2026.

Adapte sempre as recomendações à versão de Go e às convenções já presentes no repositório.

## Princípios que a IA deve preservar

- Siga o ciclo **red-green-refactor** rigorosamente: escreva o teste, veja-o falhar, implemente o mínimo para passar, depois refatore. Um teste que nasce verde não prova nada.
- Refatorar é livre enquanto os testes estão verdes — a única coisa que não é permitida durante um refactor é mudar o comportamento observável.
- Teste **comportamento observável** (a API exportada do pacote), não detalhes internos. Prefira `package nome_test` (teste de caixa preta) quando o pacote não precisar acessar identificadores não exportados, para forçar essa disciplina.
- **Uma asserção por cenário.** Separe verificações de comportamento e de detalhe de implementação em subtestes distintos em vez de acumular tudo em um único `Test...`.
- Não afirme o texto exato de uma mensagem de erro — mensagens mudam. Verifique apenas se o erro é `nil` ou não, a menos que o texto seja parte do contrato público.
- Determinismo: nenhum teste deve depender da ordem de execução, de tempo real (`time.Sleep` sem abstração) ou de concorrência não controlada.

## Estrutura e nomenclatura

- Arquivo `nome_test.go` ao lado do arquivo `nome.go` que ele testa — é a convenção que o toolchain do Go espera.
- Função de teste de função: `TestNomeDaFuncao(t *testing.T)`; para método: `TestStruct_Metodo(t *testing.T)`.
- **Caixa preta vs. caixa branca:** use `package foo_test` quando o teste só precisa da API exportada de `foo` (reforça que o teste vale do ponto de vista do consumidor do pacote); use o mesmo pacote (`package foo`) apenas quando for genuinamente necessário acessar algo não exportado.
- Nomeie testes e subtestes descrevendo o comportamento esperado, não a implementação (`TestCompleteTask_SetsCompletedAtTimestamp`, não `TestCompleteTask_CallsRepositoryUpdate`).

## Table-Driven Tests

Reduza duplicação reunindo casos análogos em uma tabela (slice de structs) e iterando com `t.Run` para gerar subtestes nomeados:

```go
func TestFooer(t *testing.T) {
    tests := []struct {
        name  string
        input int
        want  string
    }{
        {"nove deve ser Foo", 9, "Foo"},
        {"tres deve ser Foo", 3, "Foo"},
        {"dois nao deve ser Foo", 2, ""},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Fooer(tt.input)
            if got != tt.want {
                t.Errorf("Fooer(%d) = %q, want %q", tt.input, got, tt.want)
            }
        })
    }
}
```

**Não infle a tabela indefinidamente.** Se um cenário exige campos condicionais que só fazem sentido para alguns casos, isso é sinal de que ele não pertence àquela tabela — escreva um teste separado em vez de forçar mais uma coluna (ver Antipadrões).

## Subtests e Paralelismo

- `t.Run(nome, func(t *testing.T) {...})` agrupa cenários relacionados sob uma função "guarda-chuva" e produz saída hierárquica (`TestFooer/nove_deve_ser_Foo`), permitindo rodar um caso isolado com `-run`.
- `t.Parallel()`, chamado dentro de um subteste, marca-o para rodar em paralelo com os demais subtestes paralelos do mesmo nível — use quando os casos são independentes e não compartilham estado mutável.
- Em Go < 1.22, a variável de loop capturada pela closure do subteste precisa ser copiada localmente (`tt := tt`) antes de `t.Run`, ou todos os subtestes paralelos acabam enxergando o valor da última iteração.

## Setup, Cleanup e TestMain

- Prefira `t.Cleanup(func() { ... })` a `defer` solto para liberar recursos — roda mesmo se o teste sofrer `panic`, e compõe bem quando um helper registra sua própria limpeza internamente.
- `t.TempDir()` cria um diretório temporário e agenda sua remoção automaticamente ao final do teste.
- `TestMain(m *testing.M)`, declarado uma vez por pacote de teste, permite setup/teardown de escopo de pacote (subir um container, aplicar migrations em um banco de teste). Sempre finalize com `os.Exit(m.Run())`:

```go
func TestMain(m *testing.M) {
    // setup de pacote (ex.: subir dependências de teste)
    code := m.Run()
    // teardown de pacote
    os.Exit(code)
}
```

## Interfaces, Injeção de Dependência e Dublês

O princípio central: **código bem projetado é fácil de testar** — dificuldade para mockar é sinal de design, não de fraqueza do processo de TDD.

- Defina interfaces pequenas **no pacote consumidor**, não no pacote que implementa (o mesmo princípio de "aceite interfaces, retorne structs" da skill `api-and-interface-design`).
- Injete dependências como parâmetros em vez de acessar globais. Trocar `os.Stdout` por um `io.Writer` recebido como argumento, ou um relógio/`Sleeper` concreto por uma interface mínima, é o que torna o código testável sem esforço:

```go
type Sleeper interface {
    Sleep()
}

func Countdown(out io.Writer, sleeper Sleeper) {
    for i := 3; i > 0; i-- {
        fmt.Fprintln(out, i)
        sleeper.Sleep()
    }
    fmt.Fprint(out, "Vai!")
}
```

  No teste, injete um `bytes.Buffer` no lugar de `os.Stdout` e um **spy** no lugar do `Sleeper` real:

```go
type SpySleeper struct {
    Calls int
}

func (s *SpySleeper) Sleep() { s.Calls++ }
```

  Um **spy** registra como foi chamado (quantas vezes, com quais argumentos); um **mock** (via `testify/mock`, `gomock` ou similar) verifica uma expectativa de interação específica. Não confunda os dois papéis sem necessidade.

- **Se um teste precisa de mais de ~3 dublês, é sinal de alerta de design** — geralmente indica uma interface grande demais (que deveria ser quebrada em métodos mais coesos) ou dependências que deveriam ser consolidadas em uma abstração única. Prefira:

```go
// Em vez de expor cada dependência de baixo nível ao handler...
func NewRegistrationHandler(userStore UserStore, emailer Emailer) http.HandlerFunc

// ...consolide a lógica de negócio numa abstração coerente
func NewRegistrationHandler(userService UserService) http.HandlerFunc
```

- Nunca exporte um campo ou método só para viabilizar um teste — isso vaza detalhe de implementação e confunde quem consome o pacote. Teste a partir da perspectiva de um consumidor real da API.

## Testes Solitários vs. Sociáveis (Unitário vs. Integração)

- **Solitary (unitário):** todas as dependências são dublês; rápido, isolado, determinístico.
- **Sociable (integração):** usa dependências reais (ou parcialmente reais) quando o próprio comportamento da integração é o que precisa ser validado — uma query SQL real, uma migration, uma chamada HTTP contra um servidor de teste com `httptest`.
- Separe os dois claramente (sufixo de arquivo, build tag, ou pacote `_test` dedicado) e rode-os em estágios diferentes do CI — testes sociáveis são mais lentos e não devem bloquear o feedback rápido dos unitários.

## Fuzzing

Nativo desde Go 1.18 — útil para funções de parsing, serialização, ou qualquer lógica com espaço de entrada grande:

```go
func FuzzReverse(f *testing.F) {
    f.Add("word1")
    f.Fuzz(func(t *testing.T, a string) {
        rev := Reverse(a)
        doubleRev := Reverse(rev)
        if a != doubleRev {
            t.Errorf("Reverse(Reverse(%q)) = %q, want %q", a, doubleRev, a)
        }
    })
}
```

Rode localmente com `go test -fuzz=FuzzReverse` (limite a duração em CI com `-fuzztime`). Entradas que quebram o teste viram arquivos de corpus versionáveis em `testdata/fuzz/`.

## Cobertura

```bash
go test -cover ./...
go test -coverprofile=cover.out -covermode=atomic ./...   # atomic é necessário com -race/paralelismo
go tool cover -html=cover.out -o cover.html                # relatório visual navegável
```

Cobertura alta não substitui asserções significativas — trate o número como sinal de áreas não exercitadas, nunca como meta em si.

## Benchmarks

```go
func BenchmarkFooer(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Fooer(i)
    }
}
```

Rode com `go test -bench=. -benchmem`. Se o benchmark tiver um setup caro antes do loop, chame `b.ResetTimer()` logo após o setup para não contaminar a medição. Use `benchstat` para comparar duas execuções (antes/depois de uma otimização) de forma estatisticamente válida, em vez de comparar números brutos a olho.

## Antipadrões a Evitar

1. **Pular o ciclo red-green-refactor** — implementar antes de ver o teste falhar não prova que o teste testa alguma coisa.
2. **Confundir refatoração com mudança de comportamento** — refatorar pode reestruturar o código livremente; o que não pode é mudar o que o código faz de fora para dentro.
3. **Testes "evergreen"** que nunca falham, independentemente do que aconteça com o código — não protegem contra nada.
4. **Asserções sem contexto útil** (`t.Error("false != true")`) — a mensagem de falha deve dizer o que foi observado e o que era esperado.
5. **Comparar o objeto inteiro quando só um campo importa** para aquele cenário — acopla o teste a dados irrelevantes e o deixa frágil a mudanças não relacionadas.
6. **Múltiplas asserções não relacionadas no mesmo teste** — dificulta diagnosticar qual delas falhou; separe em subtestes.
7. **Ignorar o que os testes estão "dizendo"** — setup difícil de montar é sinal de que o próprio código é difícil de usar, não só de testar.
8. **Setup gigante ou dependência de muitos dublês** — sinal de dependências mal consolidadas ou de uma interface vazada (grande demais).
9. **Exportar algo só para viabilizar teste** — viola encapsulamento e confunde consumidores reais do pacote.
10. **Table-driven test inflado** com campos condicionais para casos que não se encaixam de verdade na tabela — não tenha medo de sair da tabela e escrever um teste separado.

## Checklist para uma skill de IA

Antes de finalizar uma mudança em testes Go, verificar:

1. O teste nasceu falhando antes da implementação (RED confirmado)?
2. O caso valida comportamento observável (via API exportada), com um único motivo principal para falhar?
3. É determinístico — sem dependência de ordem de execução, tempo real ou concorrência não controlada?
4. Casos análogos estão organizados como table-driven test, com subtestes nomeados via `t.Run`?
5. As dependências foram injetadas via interfaces pequenas definidas pelo consumidor, em vez de acessadas globalmente?
6. O número de dublês/mocks no teste está sob controle (≤ ~3)? Se não, o design do código pede revisão?
7. Cleanup usa `t.Cleanup`/`t.TempDir` em vez de `defer` solto ou limpeza manual esquecida?
8. Testes sociáveis (integração) estão separados dos solitários (unitários) e identificáveis como tal?
9. Cobertura — e, quando aplicável, benchmarks ou fuzzing — foram considerados para o código alterado?
10. Foi executado pelo menos o teste/pacote afetado, usando o comando real do projeto (`go test ./...` ou o equivalente já adotado no repositório)?
