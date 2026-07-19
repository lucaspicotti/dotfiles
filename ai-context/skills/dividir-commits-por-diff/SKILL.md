---

name: split-commits-by-diff
description: Divide commits do Git por trechos do diff para criar alterações limpas e bem delimitadas.
------------------------------------------------------------------------------------------------------

# Dividir Commits por Diff

Use esta skill para transformar uma árvore de trabalho com alterações misturadas em commits limpos e bem delimitados.

## Resultados Esperados

* Produzir um plano de commits antes de alterar o index.
* Manter cada commit focado em uma única intenção (`feature`, `fix`, `refactor`, `docs`, `test` ou `chore`).
* Preservar as alterações do usuário, evitando adicionar arquivos ou trechos por engano.
* Criar mensagens de commit claras, explicando por que cada commit existe.

## Regras de Segurança

* Nunca execute comandos destrutivos do Git (`reset --hard`, `checkout --`, `push --force`) a menos que o usuário solicite explicitamente.
* Nunca reescreva o histórico (`commit --amend`, `rebase`) a menos que o usuário solicite explicitamente.
* Nunca faça commit de segredos ou arquivos semelhantes a credenciais (`.env`, arquivos de chave, dumps de tokens).
* Se hooks de pre-commit modificarem arquivos, inclua essas alterações em um novo commit, salvo se o usuário solicitar outra abordagem.
* Se não houver alterações reais, não crie um commit vazio.

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

Para cada grupo proposto, defina:

* Nome do grupo, de forma breve.
* Arquivos e trechos incluídos.
* Justificativa, explicando por que o agrupamento é coerente.
* Rascunho da mensagem de commit.

Se um trecho do arquivo pertencer a uma intenção diferente do restante, utilize adição interativa por patch.

### 3) Adicionar ao stage apenas as alterações do grupo atual

Estratégia padrão de stage:

* Adicione o arquivo inteiro quando ele possuir uma única intenção: `git add <arquivo>`
* Adicione por trechos quando o arquivo contiver alterações com intenções diferentes: `git add -p <arquivo>`

Se a seleção interativa de trechos não estiver disponível no ambiente de execução, utilize esta alternativa:

1. Adicione o arquivo inteiro ao stage.
2. Remova do stage os arquivos ou trechos não desejados utilizando `git restore --staged` para os arquivos específicos.
3. Repita o processo até que `git diff --cached` corresponda exatamente ao grupo atual.

### 4) Criar o commit do grupo atual

Crie o commit com uma mensagem curta e alinhada ao padrão do repositório.

Diretrizes para a mensagem:

* Primeira linha: resumo curto no modo imperativo.
* Corpo opcional: uma ou duas linhas explicando o motivo da alteração.
* Utilize prefixos semânticos somente se o repositório já seguir esse padrão.
* Sempre escreva o resumo em português

Exemplos:

* `fix(auth): evita gravações duplicadas do refresh token`
* `refactor(blog): extrai helper de normalização de locale`
* `docs: esclarece fluxo de invalidação do cache`

### 5) Validar e continuar

Após cada commit, execute:

```bash
git show --stat --oneline -1
git status --short
```

Depois, repita o processo de stage e commit para o próximo grupo até concluir todas as alterações.

### 6) Verificação final

Ao final, execute:

```bash
git log --oneline -n <quantidade_de_novos_commits>
git status
```

Informe:

* Quantidade de commits criados.
* Títulos dos commits, na ordem em que foram criados.
* Arquivos que permaneceram sem commit, se houver.

## Heurísticas de Decisão

Quando a divisão não estiver clara, priorize nesta ordem:

1. Manter o repositório compilável e com os testes passando após cada commit.
2. Manter uma única alteração conceitual por commit.
3. Facilitar a leitura e a revisão dos commits.
4. Minimizar stages parciais arriscados.

Não force uma atomicidade perfeita se isso resultar em commits frágeis ou enganosos.

## Contrato de Comunicação

Quando esta skill for utilizada, comunique-se nesta sequência:

1. Resuma brevemente o formato atual do diff.
2. Apresente os grupos de commits propostos.
3. Execute o stage e o commit de cada grupo.
4. Informe a lista final de commits e o estado restante do repositório.

Seja objetivo e tome decisões. Solicite a opinião do usuário apenas quando existirem múltiplas estratégias de divisão igualmente válidas e que possam alterar significativamente o histórico.

