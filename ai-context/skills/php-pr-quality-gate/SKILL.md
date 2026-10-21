---
name: php-pr-quality-gate
description: Revisa pull requests dos projetos PHP legados Erp, VendTef, MicroMarket e PayBlu com contraditorio defensivo e validacao funcional baseada em escopo.md e pullrequest.md. Use para decidir se uma branch esta pronta para merge, confirmar bugs reais, executar testes relevantes e validar fluxos web no navegador quando aplicavel.
---

# Quality Gate de Pull Request PHP

Execute uma revisao independente e baseada em evidencias. O objetivo nao e resumir o diff, mas decidir se a mudanca satisfaz o escopo, preserva os contratos existentes e esta segura para merge.

Nao altere a implementacao durante esta skill. Comandos de diagnostico e testes proporcionais ao risco sao permitidos; qualquer teste que possa afetar dados reais, servicos externos ou producao exige autorizacao previa.

## Entradas

Leia antes de concluir:

- `escopo.md`, obrigatorio para requisitos e Definition of Done (DoD);
- `pullrequest.md`, obrigatorio para contexto e percurso de teste descrito no PR;
- instrucoes `AGENTS.md` aplicaveis;
- diff completo da branch, incluindo commits, staged, unstaged e arquivos novos;
- codigo vizinho necessario para entender chamadores, validacoes, views e persistencia.

Se `escopo.md` ou `pullrequest.md` estiver ausente, registre a lacuna explicitamente. Continue apenas com o que puder ser validado sem inventar requisitos ou resultados.

## Fluxo Obrigatorio

1. Identifique o projeto, a branch e a base de comparacao mais confiavel usando caminhos, remote do Git, manifests e historico. Nao modifique historico, stage ou working tree.
2. Extraia de `escopo.md` cada requisito e ponto de DoD. Extraia de `pullrequest.md` o comportamento alegado e cada passo do percurso de teste.
3. Leia [references/review-rules.md](references/review-rules.md) e revise primeiro os testes, depois a implementacao e o codigo adjacente.
4. Registre hipoteses de falha com causa raiz, cenario reproduzivel, impacto e evidencia precisa no codigo.
5. Para cada hipotese, leia e aplique [references/defensive-protocol.md](references/defensive-protocol.md). Tente refutar o apontamento antes de confirma-lo. Nao publique suspeitas sem sustentacao.
6. Leia [references/test-protocol.md](references/test-protocol.md), monte a matriz de validacao e execute os testes seguros e relevantes. Testes devem validar tanto o percurso do PR quanto todos os pontos de DoD.
7. Se houver comportamento executado no navegador, use Chrome DevTools MCP quando estiver disponivel e a validacao dinamica agregar evidencia. Para mudancas exclusivamente backend ou CLI, nao use navegador.
8. Reconcilie a analise estatica, o contraditorio e os resultados observados. Um teste verde nao invalida um bug arquitetural ou de seguranca; um teste vermelho so prova um problema quando a causa estiver isolada da infraestrutura.
9. Leia [references/output-contract.md](references/output-contract.md) e grave `review.md` e `.agy_issues.json` na raiz do projeto conforme o contrato de saida abaixo.

## Criterio de Emissao

Publique um item somente quando houver evidencia verificavel e impacto concreto:

- `[BUG CONFIRMADO]`: a defesa falhou e o defeito e reproduzivel ou demonstravel pelo fluxo do codigo;
- `[PARCIALMENTE PROCEDENTE / RISCO MITIGADO]`: parte da alegacao procede, mas uma garantia comprovada reduz probabilidade ou impacto;
- `[FALSO POSITIVO]`: a defesa comprovou que o risco nao ocorre. Nao inclua em `.agy_issues.json`; mencione em `review.md` apenas se a refutacao for util para a decisao.

Classifique itens confirmados como `[RISCO ALTO]`, `[RISCO MEDIO]`, `[RISCO BAIXO]` ou `[FORA DO ESCOPO]`. Ordene por risco e impacto. Nao use emojis nem elementos decorativos.

## Quality Gate

Aprove somente quando:

- nao restarem bugs confirmados de risco alto ou medio que bloqueiem o merge;
- todos os pontos de DoD estiverem `ATENDIDO` ou tiverem impedimento objetivo documentado;
- o percurso do PR estiver validado, ou cada etapa nao executada estiver marcada como `NAO EXECUTADA` com motivo;
- testes automatizados, build e validacoes estaticas relevantes passarem;
- fluxos web alterados tiverem evidencia de navegador quando essa for necessaria e viavel;
- a historia de verificacao diferenciar fatos observados de inferencias.

Nunca declare que um teste passou se ele nao foi executado. Use `BLOQUEADO` para dependencia indisponivel e `NAO APLICAVEL` somente com justificativa tecnica.

## Contrato de Saida

Em `review.md`, inclua:

1. contexto, projeto identificado, base do diff e resumo do escopo;
2. achados confirmados no formato obrigatorio de [references/output-contract.md](references/output-contract.md), com status, risco, localizacao na linha do arquivo, causa raiz, defesa tentada, veredito e correcao proposta;
3. tabela de DoD: requisito, validacao, evidencia e status;
4. tabela do percurso do PR: passo, resultado esperado, resultado observado e status;
5. testes executados com comando ou acao, resultado e evidencias; inclua validacoes de navegador separadamente;
6. hipoteses descartadas relevantes e a garantia que as refutou;
7. veredito final: `APROVAR`, `SOLICITAR ALTERACOES` ou `BLOQUEADO`, com justificativa curta.

Use links remotos no formato do servidor do projeto, apontando para a linha do arquivo na branch, nao para a linha do diff. Se nao for possivel construir um link correto, use `caminho#Llinha` e declare a limitacao; nao invente URL, branch ou linha.

Em `.agy_issues.json`, grave um array JSON valido. Inclua apenas bugs confirmados e riscos parcialmente procedentes que demandem acao:

```json
[
  {
    "id": 1,
    "severity": "[RISCO ALTO]",
    "title": "Titulo objetivo",
    "file": "caminho/do/arquivo.php#L10",
    "description": "Causa raiz, cenario de falha e impacto"
  }
]
```

Quando nao houver itens acionaveis, grave `[]`.
