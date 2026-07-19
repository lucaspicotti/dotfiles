---

name: generate-pr-description
description: Gera o título e a descrição de um Pull Request com base nas alterações da branch, seguindo obrigatoriamente o arquivo `template.md` localizado no mesmo diretório da skill. Use sempre que o usuário quiser preparar o texto de um PR para copiar no GitHub, Git Café, LazyGit ou outra interface.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Gerar Descrição de Pull Request

Use esta skill para gerar o título e o corpo de um Pull Request com base nas alterações da branch atual, seguindo o formato definido no arquivo `template.md`.

Esta skill produz apenas o texto do Pull Request. Ela não cria o PR, não executa push e não modifica commits ou arquivos do repositório.

## Resultados Esperados

* Ler o arquivo `template.md` localizado no mesmo diretório desta skill.
* Analisar as alterações da branch atual.
* Gerar um título curto e objetivo para o Pull Request.
* Preencher as seções do template com informações concretas.
* Remover instruções e placeholders que não devem aparecer no texto final.
* Entregar o conteúdo pronto para copiar e colar em qualquer ferramenta de criação de PR.

## Fonte do Template

O template obrigatório está localizado em:

```text
template.md
```

Considere que o caminho é relativo ao diretório desta skill.

O arquivo deve ser lido antes da geração do conteúdo.

Regras:

* Preserve a estrutura e a ordem das seções do template.
* Preserve títulos, listas, checklists e demais elementos Markdown.
* Substitua placeholders por informações reais extraídas da branch.
* Remova comentários instrutivos que não façam parte do conteúdo final.
* Não crie uma estrutura alternativa quando o template estiver disponível.
* Não altere o arquivo `template.md`.

Se o arquivo `template.md` não existir ou não puder ser lido, informe o problema e não invente um template diferente.

## Segurança e Escopo

* Não execute `git push`.
* Não execute `gh pr create`.
* Não abra ou crie Pull Requests.
* Não crie, altere ou reorganize commits.
* Não adicione arquivos ao stage.
* Não modifique nenhum arquivo do repositório.
* Não execute comandos destrutivos do Git.
* Utilize comandos Git apenas para leitura e análise.
* Não inclua segredos, tokens, credenciais ou valores sensíveis na descrição.

## Fluxo de Trabalho

### 1) Ler o template

Leia primeiro o arquivo:

```text
template.md
```

Identifique:

* Títulos e seções obrigatórias.
* Checklists existentes.
* Placeholders que precisam ser preenchidos.
* Comentários de instrução que devem ser removidos.
* Seções opcionais que podem permanecer vazias ou ser removidas.

### 2) Inspecionar o contexto da branch

Execute comandos somente de leitura:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -n 20
```

Determine a branch base do repositório quando possível.

Se a branch base estiver disponível, analise também:

```bash
git log <base>..HEAD --oneline
git diff --stat <base>...HEAD
git diff <base>...HEAD
```

Se a branch base não puder ser determinada com segurança, utilize o diff e os commits disponíveis sem presumir informações.

### 3) Compreender as alterações

Identifique:

* O principal objetivo da branch.
* Funcionalidades adicionadas.
* Bugs corrigidos.
* Refatorações realizadas.
* Alterações de interface ou comportamento.
* Testes adicionados ou modificados.
* Mudanças de configuração, documentação ou infraestrutura.
* Possíveis riscos, impactos e pontos de atenção.

Não descreva apenas os arquivos alterados. Explique o efeito e a intenção das mudanças.

### 4) Gerar o título

Crie um título:

* Curto e direto.
* Focado no resultado principal da branch.
* Compatível com o padrão de commits do repositório, quando esse padrão estiver claro.
* Sem ponto final.
* Sem informações genéricas como "ajustes diversos" ou "melhorias".

Exemplos:

```text
Corrige atualização de estoque ao cancelar nota fiscal
```

```text
Adiciona navegação inferior para dispositivos móveis
```

```text
Refatora normalização de locale do blog
```

Use prefixos semânticos apenas se o repositório já utilizar esse padrão:

```text
fix(estoque): corrige movimentação ao cancelar nota fiscal
```

### 5) Preencher o template

Preencha o conteúdo de `template.md` utilizando apenas informações confirmadas pelo diff, pelos commits ou pelos arquivos analisados.

Diretrizes:

* Seja objetivo.
* Explique o que mudou e por quê.
* Agrupe alterações relacionadas.
* Não invente testes executados.
* Não marque checkboxes de validações que não foram confirmadas.
* Não afirme que algo foi testado se não houver evidência.
* Utilize `Não se aplica` quando uma seção obrigatória não for relevante.
* Mantenha seções vazias somente quando o template exigir explicitamente.
* Remova textos de instrução, exemplos e placeholders do conteúdo final.

### 6) Validar o texto gerado

Antes de responder, confirme que:

* Todas as seções obrigatórias do template foram preservadas.
* Nenhum placeholder permaneceu sem tratamento.
* Comentários instrutivos foram removidos.
* O título corresponde ao objetivo principal da branch.
* A descrição corresponde às alterações reais.
* Nenhum teste não executado foi declarado como concluído.
* Nenhuma informação sensível foi incluída.
* O Markdown está válido e pronto para copiar.

## Heurísticas de Conteúdo

Ao resumir as mudanças, priorize nesta ordem:

1. Comportamento percebido pelo usuário.
2. Regra de negócio afetada.
3. Correção ou funcionalidade principal.
4. Decisões técnicas relevantes.
5. Testes e validações.
6. Detalhes internos de implementação.

Evite transformar a descrição em uma lista de arquivos modificados.

### Ruim

```text
- Alterado arquivo Produto.php
- Alterado arquivo Estoque.php
- Alterado arquivo nota.js
```

### Melhor

```text
- Corrige a movimentação de estoque ao cancelar uma nota fiscal.
- Evita que a quantidade seja atualizada duas vezes durante o estorno.
- Ajusta a interface para refletir imediatamente o novo saldo.
```

## Tratamento de Incertezas

Quando uma informação não puder ser confirmada:

* Não invente.
* Utilize uma indicação neutra, como `Não verificado`.
* Deixe a checkbox desmarcada.
* Informe brevemente a limitação após o texto gerado, quando necessário.

Quando existirem mudanças não relacionadas na mesma branch, organize-as em grupos dentro das seções existentes do template, sem criar uma estrutura paralela.

## Contrato de Resposta

A resposta final deve conter:

1. O título sugerido.
2. O corpo completo do Pull Request seguindo `template.md`.
3. Uma observação curta apenas quando houver informações não confirmadas.

Formato:

```markdown
## Título

<título sugerido>

## Descrição

<conteúdo preenchido de template.md>
```

Não execute nenhuma ação de publicação.

Não inclua instruções sobre GitHub, Git Café, LazyGit ou GitHub CLI, a menos que o usuário peça separadamente.

