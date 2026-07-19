## Estilo de código

- Funções: entre 4 e 20 linhas. Divida se ficarem maiores.
- Arquivos: menos de 500 linhas. Separe por responsabilidade.
- Uma única responsabilidade por função e uma responsabilidade por módulo (SRP).
- Nomes: específicos e únicos. Evite `data`, `handler`, `Manager`.
  Prefira nomes que retornem menos de 5 resultados ao pesquisar (`grep`) no código.
- Tipos: explícitos. Não utilize `any`, `Dict` ou funções sem tipagem.
- Evite duplicação de código. Extraia lógica compartilhada para funções ou módulos.
- Prefira retornos antecipados (*early return*) em vez de `if` aninhados. No máximo 2 níveis de indentação.
- Mensagens de exceção devem incluir o valor que causou o erro e o formato esperado.

## Comentários

- Preserve os comentários existentes. Não os remova durante refatorações — eles registram a intenção e o contexto da implementação.
- Escreva o **porquê**, não o **o quê**. Evite comentários como `// incrementa contador` acima de `i++`.
- Funções públicas devem possuir documentação (*docstring*) contendo a finalidade e um exemplo de uso.
- Referencie números de issues ou SHAs de commits quando uma linha existir devido a um bug específico ou a uma limitação externa.

## Testes

- Os testes devem ser executados por meio de um único comando. O agente deve inspecionar os arquivos da raiz do projeto (ex: `package.json`,`go.mod`, `composer.json`, etc.) para identificar o gerenciador de testes padrão (ex: `npm test`, `go test ./...`, `phpunit`) ou perguntar ao usuário caso não consiga determinar.
- Toda nova função deve possuir um teste. Correções de bugs devem incluir um teste de regressão.
- Faça *mock* de I/O externo (API, banco de dados, sistema de arquivos) utilizando classes falsas (*fakes*) nomeadas, e não *stubs* inline.
- Os testes devem seguir o princípio **F.I.R.S.T.**:
  - **Fast** (rápidos)
  - **Independent** (independentes)
  - **Repeatable** (repetíveis)
  - **Self-validating** (autovalidáveis)
  - **Timely** (escritos no momento adequado)

## Dependências

- Injete dependências por construtor ou parâmetros, e não por variáveis globais ou imports diretos.
- Encapsule bibliotecas de terceiros atrás de uma interface simples pertencente ao projeto.

## Estrutura

- Siga as convenções do framework utilizado (Rails, Django, Next.js etc.).
- Prefira módulos pequenos e focados em vez de arquivos grandes com múltiplas responsabilidades.
- Utilize uma estrutura previsível de diretórios, como `controller/model/view`, `src/lib/test` etc.

## Formatação

- Utilize o formatador padrão da linguagem (`gofmt`, `prettier`, `phpcbf`).
- Não discuta regras de estilo além das definidas pelo formatador.

## Logs

- Utilize JSON estruturado para logs de depuração e observabilidade.
- Utilize texto simples apenas para saídas de linha de comando voltadas ao usuário.
