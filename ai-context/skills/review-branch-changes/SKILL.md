---
name: review-branch-changes
description: Code review de alterações da branch, commitadas ou no working tree, usando `escopo.md` como contexto. No modo formal, grava o parecer em `review.md`. No modo colaborativo, responde no chat para revisar e corrigir a branch antes do PR. Use quando o usuário quiser detectar bugs, regressões, riscos, gaps de teste ou problemas de implementação na branch atual.
---

# Review de Alterações da Branch

Use esta skill para executar um code review rigoroso das alterações da branch atual.

O objetivo não é resumir o diff.

O objetivo é decidir se as mudanças estão seguras para avançar e registrar apenas achados reais, sustentados por evidência.

Esta skill deve considerar:

- commits já existentes na branch;
- alterações staged;
- alterações unstaged;
- arquivos novos, removidos e renomeados;
- impacto das mudanças no código vizinho e nos contratos existentes.

O contexto funcional da tarefa está em um arquivo obrigatório na raiz do projeto:

```text
escopo.md
```

Esta skill possui dois modos de saída:

```text
1. Review de terceiros: escrever em review.md
2. Review colaborativa para correção: responder no chat, sem escrever arquivo
```

## Resultado Esperado

Ao final da execução, esta skill deve:

- ler `escopo.md` antes de concluir a review;
- analisar o estado atual do Git sem modificar histórico, stage ou working tree;
- determinar a melhor base de comparação disponível;
- inspecionar os diffs e o código ao redor dos pontos alterados;
- executar validações automatizadas relevantes quando isso for possível e proporcional;
- produzir a saída no modo correto, conforme a intenção do usuário.

## Modos de Uso

### 1. Review de terceiros

Use este modo quando o usuário quiser um parecer para outra pessoa ler, copiar para o PR ou registrar formalmente a revisão.

Neste modo, a skill deve:

- escrever ou sobrescrever `review.md` na raiz do projeto;
- registrar problemas reais da branch;
- explicar o motivo de cada problema;
- sugerir uma possibilidade de correção para cada item;
- produzir texto pronto para ser usado em contexto de PR.

### 2. Review colaborativa para correção

Use este modo quando o usuário quiser revisar o próprio trabalho antes de abrir o PR e corrigir a branch junto com o agente.

Neste modo, a skill deve:

- responder no chat, sem escrever arquivo;
- apontar problemas por ordem de risco;
- propor correções objetivas e acionáveis;
- tratar a review como mecanismo de melhoria da branch;
- repetir o ciclo de revisar, corrigir e validar até a branch estar pronta para ser commitada.

Se a intenção do usuário não estiver explícita, prefira o modo colaborativo.

## Regra Central

Faça review com mentalidade de aprovação crítica de Pull Request.

Não assuma que a intenção do autor garante correção.

Toda conclusão importante deve ser sustentada por pelo menos uma destas evidências:

- diff;
- código existente;
- teste existente ou ausente;
- contrato público afetado;
- comportamento descrito em `escopo.md`.

Se não houver achados, diga isso explicitamente.

## Regras de Segurança

- Não corrigir código durante a review, salvo instrução explícita do usuário.
- Não criar commit, não fazer push e não abrir PR.
- Não adicionar nem remover arquivos do stage.
- Não executar comandos destrutivos do Git.
- Não inventar comportamento não verificado.
- Não declarar testes executados sem execução real.
- Não tratar preferência de estilo como finding.

## Fontes Obrigatórias

### 1. Contexto funcional

Leia `escopo.md` antes de fechar qualquer julgamento.

Use esse arquivo para identificar:

- objetivo da mudança;
- comportamentos que devem ser preservados;
- limites do escopo;
- riscos de negócio mais importantes;
- sinais de regressão fora do esperado.

Se `escopo.md` não existir, continue a análise técnica, mas registre explicitamente no resultado que a revisão ocorreu sem contexto funcional formal.

### 2. Estado do Git

Colete evidências com comandos de leitura.

Comandos mínimos:

```bash
git status --short
git branch --show-current
git log --oneline --decorate -n 20
git diff --cached
git diff
```

Quando possível, descubra a base correta da branch.

Prioridade de referência:

1. branch de tracking configurada;
2. branch-base inferida pelo repositório;
3. `main`;
4. `master`.

Se uma base confiável existir, analise também:

```bash
git merge-base HEAD <base>
git log <base>..HEAD --oneline
git diff --stat <base>...HEAD
git diff <base>...HEAD
```

Se a base não puder ser determinada com segurança, registre a limitação e trabalhe com `git diff`, `git diff --cached` e os commits disponíveis.

## O Que Procurar

### Correção

Procure por:

- condicionais invertidas;
- ausência de validação;
- tratamento incompleto de `nil`, `null`, vazio, erro ou timeout;
- efeitos colaterais duplicados;
- fluxo parcialmente atualizado;
- uso incorreto de API, framework ou biblioteca;
- suposições frágeis sobre ordenação, locale, timezone, precisão numérica ou estado compartilhado.

### Regressão

Procure por:

- comportamento antigo quebrado sem intenção explícita no `escopo.md`;
- quebra de contrato público;
- retorno, payload, schema, assinatura ou semântica alterados sem cobertura adequada;
- casos de borda anteriormente suportados e agora ignorados;
- perda de compatibilidade em integrações, CLI, endpoints, eventos ou persistência.

### Testes

Verifique:

- se comportamento novo possui teste;
- se correção de bug possui teste de regressão;
- se os testes alterados realmente cobrem o risco principal;
- se houve mudança arriscada sem validação automatizada proporcional.

Ausência de teste nem sempre é bug, mas é finding quando reduz materialmente a confiança da mudança.

### Manutenibilidade

Procure por:

- duplicação relevante;
- responsabilidades misturadas;
- abstração prematura;
- nomes que escondem intenção;
- complexidade desnecessária;
- acoplamento que torna a mudança frágil.

Só registre isso como finding quando houver impacto concreto em correção, evolução segura ou legibilidade crítica.

### Segurança e Performance

Avalie quando aplicável:

- exposição de segredos;
- ausência de autorização, sanitização ou validação;
- risco de N+1 ou loops redundantes;
- trabalho repetido em caminho quente;
- operações destrutivas sem guarda;
- cargas excessivas de memória, CPU ou I/O introduzidas pela mudança.

## Critério de Finding

Só registre um finding quando houver um problema concreto ou um risco plausível, específico e justificável.

Não registre sugestões vagas.

Cada finding deve responder claramente:

1. Onde está o problema?
2. Qual cenário quebra ou fica sem cobertura suficiente?
3. Por que isso importa?
4. Qual evidência sustenta a conclusão?

Se uma dessas respostas estiver fraca, refine ou descarte o finding.

## Severidade

Classifique cada finding em uma destas categorias:

- `alta`: bug provável, regressão relevante, quebra de contrato, falha de segurança ou risco de produção;
- `media`: comportamento incompleto, cobertura insuficiente em área crítica, risco considerável de manutenção ou erro em caso comum;
- `baixa`: problema real de impacto limitado.

Ordene os findings da maior para a menor severidade.

## Fluxo de Trabalho

### 1. Ler o contexto

Leia `escopo.md`.

Extraia:

- objetivo principal;
- regras de negócio sensíveis;
- comportamento esperado;
- limites explícitos de escopo.

### 2. Mapear as mudanças reais

Inspecione:

- working tree;
- stage;
- commits da branch;
- diff agregado em relação à base, quando disponível.

Separe mentalmente:

- comportamento novo;
- correções;
- refatorações;
- mudanças mecânicas;
- testes;
- configuração e infraestrutura.

### 3. Ler o código ao redor

Quando o risco depender de contexto, leia também:

- implementações chamadas pelos trechos alterados;
- interfaces e contratos públicos;
- testes existentes relacionados;
- código que consome a API alterada;
- pontos de integração e persistência.

Não conclua apenas pelo diff quando a segurança da mudança depender do comportamento do sistema ao redor.

### 4. Executar validações automatizadas

Identifique o comando padrão de testes a partir dos arquivos da raiz do projeto, como `package.json`, `go.mod`, `composer.json`, `Makefile`, `pytest.ini`, `Cargo.toml` ou equivalentes.

Quando houver comando claro e a execução for viável, rode pelo menos a validação mais relevante para a área alterada.

Se existir lint ou checagem estática claramente padronizada e diretamente relacionada ao tipo de mudança, execute também quando for proporcional.

Se não for possível identificar o comando padrão com segurança, ou se a execução falhar por limitação de ambiente, registre isso explicitamente no resultado final.

### 5. Formular os achados

Para cada achado:

- aponte arquivo e linha quando possível;
- descreva o problema com objetividade;
- explique o impacto provável;
- sustente a conclusão com evidência observável;
- recomende a correção esperada ou a validação pendente.

Evite findings duplicados sobre a mesma causa raiz.

### 6. Produzir a saída no modo correto

Se o modo for review de terceiros, escreva ou sobrescreva `review.md` na raiz do projeto.

Se o modo for review colaborativa para correção, responda no chat e não escreva arquivo.

No modo colaborativo, a revisão pode ser seguida imediatamente por correções na branch, novas validações e nova rodada de review.

O ciclo esperado neste modo é:

1. revisar;
2. apontar problemas no chat;
3. corrigir junto com o desenvolvedor ou diretamente quando isso for o objetivo da sessão;
4. validar as correções;
5. repetir até a branch estar pronta para ser commitada.

## Formato Obrigatório de `review.md`

Use exatamente esta estrutura:

```markdown
# Code Review

## Contexto

- Branch analisada: <nome-ou-nao-verificado>
- Escopo: <resumo curto com base em escopo.md ou "Nao informado">
- Base de comparacao: <branch base ou "Nao verificada">
- Estado analisado: <commits, staged, unstaged>

## Problemas

### <alta|media|baixa> - <titulo curto do problema>

- Local: `caminho/arquivo.ext:123`
- Problema: <descricao objetiva>
- Motivo: <por que isso e um problema>
- Impacto: <efeito esperado ou regressao possivel>
- Evidencia: <cenario, contrato, diff ou ausencia de teste>
- Possibilidade de correcao: <ajuste esperado ou ponto a validar>

## Perguntas Abertas

- <somente se existir duvida real que afete a confianca da review>

## Resumo

- <quantidade de findings e risco geral>
- <cobertura de testes observada ou lacunas relevantes>
- <validacoes executadas ou "Nenhuma validacao automatizada executada">
```

## Regras de Escrita de `review.md`

- Se não houver problemas, a seção `## Problemas` deve conter exatamente `Nenhum problema identificado.`
- Se não houver perguntas abertas, a seção `## Perguntas Abertas` deve conter exatamente `Nenhuma.`
- Não use linguagem genérica como `pode melhorar` sem explicar risco concreto.
- Referencie arquivos e linhas sempre que possível.
- Não inclua elogios, agradecimentos ou texto social.
- Não inclua resumo antes dos problemas.
- Não cole diffs inteiros no arquivo final.
- Não transforme o resultado em checklist de estilo.

## Formato da Resposta no Modo Colaborativo

No modo colaborativo, a resposta no chat deve seguir esta ordem:

1. findings por severidade;
2. perguntas abertas, se houver;
3. resumo curto do risco geral;
4. proposta objetiva do próximo passo de correção.

Cada finding no chat deve conter, quando possível:

- local;
- problema;
- motivo;
- impacto;
- possibilidade de correção.

Se não houver problemas, diga explicitamente que a branch parece pronta para commit ou explique qual validação ainda falta para ter essa confiança.

## Heurísticas de Qualidade

Ao escolher onde aprofundar a análise, priorize nesta ordem:

1. mudanças que afetam comportamento percebido pelo usuário;
2. regras de negócio sensíveis descritas em `escopo.md`;
3. contratos públicos e integrações;
4. correções sem teste de regressão;
5. trechos com lógica condicional nova ou alterada;
6. alterações com grande diff mas pouca validação automatizada.

Poucos findings fortes são melhores que muitos palpites fracos.

## Tratamento de Incerteza

Quando a conclusão depender de hipótese:

- deixe a hipótese explícita;
- reduza a severidade se a evidência não sustentar algo maior;
- mova para `Perguntas Abertas` quando a dúvida impedir uma afirmação responsável;
- nunca invente certeza.

Quando houver mudanças não relacionadas misturadas na mesma branch, revise cada grupo pelo seu próprio risco, mas mantenha uma única saída no modo escolhido.

## Critérios de Conclusão

Esta skill foi bem executada quando:

- `escopo.md` foi lido ou sua ausência foi registrada;
- commits, staged e unstaged foram considerados;
- a base da branch foi determinada ou a limitação foi registrada;
- o código ao redor foi lido quando necessário;
- validações automatizadas relevantes foram executadas ou a limitação foi registrada;
- cada finding possui evidência e impacto claros;
- no modo formal, `review.md` foi escrito na raiz do projeto;
- no modo colaborativo, a revisão foi apresentada no chat de forma acionável;
- a saída final está objetiva, acionável e sem achismos.
