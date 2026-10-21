---
name: split-commits-by-diff
description: Divide commits do Git por trechos do diff para criar alterações limpas e bem delimitadas.
---

# Dividir Commits por Diff

Use esta skill para transformar uma árvore de trabalho com alterações misturadas em commits limpos e bem delimitados.

## Resultados Esperados

* Produzir um plano de commits antes de alterar o index.
* Manter cada commit focado em uma única intenção (`feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `style`, `chore`, `build`, `ci` ou `revert`).
* Preservar as alterações do usuário, evitando adicionar arquivos ou trechos por engano.
* Criar mensagens de commit claras, explicando por que cada commit existe.

## Regras de Segurança

* Nunca execute comandos destrutivos do Git (`reset --hard`, `checkout --`, `push --force`) a menos que o usuário solicite explicitamente.
* Nunca reescreva o histórico (`commit --amend`, `rebase`) a menos que o usuário solicite explicitamente.
* Nunca faça commit de segredos ou arquivos semelhantes a credenciais (`.env`, arquivos de chave, dumps de tokens).
* Se hooks de pre-commit modificarem arquivos, inclua essas alterações em um novo commit, salvo se o usuário solicitar outra abordagem.
* Se não houver alterações reais, não crie um commit vazio.
* **Commit só com ordem explícita do usuário.** A autorização vale para aquele commit (aquela fatia): nunca encadeie o commit seguinte sem nova ordem, nem pergunte e commite no mesmo passo. "Preparar o commit" é montar o stage e a mensagem, não commitar.
* Nunca inclua no commit arquivos que não são da tarefa (por exemplo um `.gitignore` alterado pelo usuário, `PROGRESSO.md`, `tasks/`): deixe-os no working tree e cite-os no relatório.
* Não adicione o trailer `Co-Authored-By` nas mensagens.

## Fluxo de Trabalho

### 1) Inspecionar o estado do repositório

Execute primeiro:

```bash
git status --short
git diff
git diff --cached
git log -n 12 --pretty=format:"%h %s"
```

Entenda:

* Quais arquivos foram modificados e se estão adicionados ou não ao stage.
* Se as alterações representam uma única responsabilidade ou múltiplas responsabilidades.
* O padrão de mensagens de commit utilizado pelo repositório.

### 2) Criar um plano de agrupamento dos commits

Crie uma proposta de agrupamento antes de adicionar qualquer alteração ao stage:

* Agrupe por intenção, não apenas pelo caminho dos arquivos.
* Mantenha alterações dependentes no mesmo commit quando separá-las puder quebrar os testes ou a build.
* Para um diff médio com alterações misturadas, prefira entre 2 e 6 commits. Evite dividir excessivamente alterações muito pequenas.
* Mire **100 a 300 linhas alteradas por commit** (ver "Tamanho dos commits"). Meça cada grupo proposto e divida os que passarem de 400 linhas antes de adicionar qualquer coisa ao stage.

Para cada grupo proposto, defina:

* Nome do grupo, de forma breve.
* Arquivos e trechos incluídos.
* Justificativa, explicando por que o agrupamento é coerente.
* Rascunho da mensagem de commit.
* Tamanho estimado (linhas adicionadas + removidas) e a faixa da tabela de tamanho em que ele cai.

Se um trecho do arquivo pertencer a uma intenção diferente do restante, utilize adição interativa por patch.

### 3) Adicionar ao stage apenas as alterações do grupo atual

Estratégia padrão de stage:

* Adicione o arquivo inteiro quando ele possuir uma única intenção: `git add <arquivo>`
* Adicione por trechos quando o arquivo contiver alterações com intenções diferentes: `git add -p <arquivo>`

Se a seleção interativa de trechos não estiver disponível no ambiente de execução (é o caso do Claude Code: `git add -p` não funciona), utilize esta alternativa, que não toca no working tree:

1. Crie uma worktree temporária no `HEAD` (`git worktree add --detach <scratchpad>/wt HEAD`).
2. Monte nela a versão de cada arquivo como ele deve ficar **depois deste commit** (copiando arquivos inteiros do working tree ou aplicando só os trechos do grupo com um script, com backup).
3. Valide a fatia na worktree: build, testes focados e, se possível, a validação completa do projeto (ex.: `make ci`); regenere ali código gerado que dependa só da fatia (ex.: `make generate`).
4. Leve cada arquivo ao index sem alterar o working tree: `git update-index --cacheinfo 100644,$(git hash-object -w <wt>/<arquivo>),<arquivo>`.
5. Confira com `git diff --cached --shortstat` e `git diff --cached`; o working tree continua com todas as alterações.
6. As fatias seguintes são montadas na mesma worktree (cumulativa). Ao final, remova-a com `git worktree remove`.

Para arquivos inteiros, basta `git add <arquivo>`; para tirar do stage, `git restore --staged <arquivo>`.

### 4) Criar o commit do grupo atual

Antes de commitar, mostre ao usuário a fatia (arquivos, `git diff --cached --shortstat`) e a mensagem proposta, e espere a ordem de commit. Crie o commit com uma mensagem curta e alinhada ao padrão do repositório (use `git commit -F -` com heredoc para o corpo).

#### Idioma da mensagem

* **GoOcppServer** (`/var/www/GoOcppServer`): título e corpo **em inglês**.
* **Demais projetos** (Erp, VendTef, MicroMarket, PayBlu, etc.): título e corpo **em português**.
* Em repositório novo ou não listado, siga o idioma predominante do histórico (`git log -n 20`); na dúvida, português.

#### Formato do título do commit

Quando o repositório utilizar Conventional Commits, siga este formato:

```text
<tipo>(<escopo>): <resumo no idioma do projeto>
```

O escopo é opcional. Quando não houver um escopo claro, utilize:

```text
<tipo>: <resumo no idioma do projeto>
```

Tipos permitidos:

* `feat`: nova funcionalidade ou capacidade do sistema.
* `fix`: correção de bug ou comportamento incorreto.
* `refactor`: alteração interna de código sem corrigir bug nem adicionar funcionalidade.
* `perf`: melhoria de performance.
* `test`: criação, alteração ou correção de testes.
* `docs`: documentação.
* `style`: formatação, lint, espaçamento ou padronização sem mudança de lógica.
* `chore`: manutenção geral, configuração ou tarefas auxiliares que não alteram diretamente a funcionalidade.
* `build`: alterações em dependências, empacotamento ou processo de build.
* `ci`: alterações em pipelines, workflows ou configuração de integração contínua.
* `revert`: reversão de uma alteração anterior.

Regras para o título:

* Escreva o resumo no idioma do projeto (ver "Idioma da mensagem").
* Use o modo imperativo no resumo (em inglês, verbo no imperativo: `add`, `keep`, `record`).
* Mantenha o título curto, específico e focado em uma única intenção.
* Não finalize o título com ponto.
* Use escopo quando ele ajudar a identificar claramente o módulo, domínio ou componente afetado.
* Não use um tipo genérico se houver um tipo mais específico que represente melhor a alteração.
* Preserve o padrão existente do repositório caso ele já utilize uma convenção compatível, ajustando apenas o necessário.

Exemplos:

* `feat(relatorios): adiciona filtro por período`
* `fix(auth): evita gravações duplicadas do refresh token`
* `refactor(blog): extrai helper de normalização de locale`
* `perf(database): reduz consultas duplicadas`
* `test(pagamento): adiciona testes de cancelamento`
* `docs(api): documenta endpoint de NFC-e`
* `style: ajusta formatação conforme PSR-12`
* `chore(composer): atualiza configuração do projeto`
* `build: atualiza dependências do Composer`
* `ci: adiciona etapa de testes ao pipeline`
* `revert: reverte alteração no checkout`

Exemplos no GoOcppServer (inglês):

* `feat(eventrelay): publish the outbox events in rounds`
* `fix(outbox): keep the write order under concurrent writers`
* `test(ocpp16): wait for the recorded connection before sending commands`
* `docs: describe the outbox, the relay and the binary without publisher`

Se o repositório não utilizar prefixos semânticos, preserve o padrão já adotado no histórico. Ainda assim, mantenha o resumo curto, imperativo e no idioma do projeto.

#### Corpo da mensagem

O corpo é **sempre resumido**: o diff e os testes já contam os detalhes.

Diretrizes:

* Primeira linha: título seguindo o formato definido acima; linha em branco antes do corpo.
* Corpo: um parágrafo curto com o porquê e o quê e, se precisar, poucos bullets; no total, cerca de **10 a 12 linhas** no máximo, quebradas em ~72 colunas.
* Quando a tarefa é dividida em vários commits, cada corpo se sustenta sozinho (o contexto daquela fatia), mas continua curto.
* Em trabalho com TDD, feche com no máximo duas linhas: `RED:` (a falha observada) e `Verification:` (comandos que passaram), no idioma do projeto (`RED:`/`Verificação:` em português). Não liste teste por teste nem mutações.
* Evite repetir no corpo o que já está evidente no título.
* Sem trailer `Co-Authored-By`.

Exemplo (GoOcppServer):

```text
fix(outbox): keep the write order under concurrent writers

seq was taken at the INSERT, before the commit, so a writer that
committed later could be delivered first. Append now buffers the batch
and WithinTx writes it last, under a writers' advisory lock held until
the commit: seq follows the commit order.

RED: TestConcurrentWritersNeverInvertTheOrder delivered [e2 e1].
Verification: make ci, make sqlc-check and make integration.
```

### 5) Validar e continuar

Após cada commit, execute:

```bash
git show --stat --oneline -1
git status --short
```

Depois, monte o stage do próximo grupo, mostre-o com a mensagem e espere a nova ordem de commit; repita até concluir todas as alterações.

### 6) Verificação final

Ao final, execute:

```bash
git log --oneline -n <quantidade_de_novos_commits>
git status
```

Informe:

* Quantidade de commits criados.
* Títulos dos commits, na ordem em que foram criados, com as linhas alteradas de cada um (`git show --shortstat --oneline <commit>`).
* Arquivos que permaneceram sem commit, se houver.

## Tamanho dos commits

Objetivo: **100 a 300 linhas alteradas por commit** (adições + remoções, `git diff --cached --shortstat`). Commits grandes são difíceis de revisar; a média de ~1000 linhas por commit é alta demais.

| Linhas alteradas | Avaliação |
|---|---|
| 20 – 100 | excelente para mudanças isoladas e fácil de revisar |
| 100 – 200 | bom, desde que tenha responsabilidade clara |
| 200 – 400 | moderado: vale avaliar se pode ser dividido |
| 400 – 800 | grande: geralmente exige mais esforço de revisão; dividir |
| 800+ | muito grande: verificar a possibilidade de divisão |

Como medir e decidir:

* Antes de cada commit, rode `git diff --cached --shortstat` e informe o total no plano e no relatório final.
* Código gerado (por exemplo sqlc, mocks, lockfiles) e fixtures entram na conta, mas podem ser apontados à parte; se só eles empurram o commit para cima da faixa, isso é aceitável quando estão no mesmo commit da mudança que os gerou.
* Testes contam: um commit com a implementação e os testes dela é preferível a separar teste e código, mas se o conjunto passar de 400 linhas, divida por comportamento (cada commit com o seu código e os seus testes), não por tipo de arquivo.
* Formas usuais de dividir uma mudança grande sem quebrar a build:
  1. domínio/tipos e seus testes primeiro, depois quem os usa;
  2. migration + queries + código gerado num commit, repositório e testes de integração no seguinte;
  3. refatoração preparatória (sem mudança de comportamento) separada da mudança de comportamento;
  4. um commit por regra ou cenário quando a mudança tem vários comportamentos independentes;
  5. documentação (`AGENTS.md`, README) no commit da mudança que ela descreve, ou num commit `docs` próprio quando for extensa.
* Cada commit continua compilável e com os testes passando: o tamanho nunca justifica um commit quebrado. Se não der para dividir sem quebrar, explique isso no plano.
* Ao planejar trabalho novo (antes de escrever o código), já divida as tarefas em fatias que caibam na faixa, em vez de dividir depois.

## Heurísticas de Decisão

Quando a divisão não estiver clara, priorize nesta ordem:

1. Manter o repositório compilável e com os testes passando após cada commit.
2. Manter uma única alteração conceitual por commit.
3. Facilitar a leitura e a revisão dos commits.
4. Minimizar stages parciais arriscados.

Não force uma atomicidade perfeita se isso resultar em commits frágeis ou enganosos.

## Contrato de Comunicação

Quando esta skill for utilizada, comunique-se nesta sequência:

1. Resuma brevemente o formato atual do diff e o total de linhas.
2. Apresente os grupos de commits propostos, com o tamanho de cada um.
3. Monte o stage do primeiro grupo e mostre a mensagem proposta; commite só com a ordem do usuário, um grupo por vez.
4. Informe a lista final de commits e o estado restante do repositório.

Seja objetivo e tome decisões. Solicite a opinião do usuário apenas quando existirem múltiplas estratégias de divisão igualmente válidas e que possam alterar significativamente o histórico.
