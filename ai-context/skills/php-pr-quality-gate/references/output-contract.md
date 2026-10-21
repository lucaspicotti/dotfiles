# Contrato do Parecer

## Item de Review

Use esta estrutura para cada bug confirmado ou risco parcialmente procedente:

````markdown
### Item N: [Titulo resumido]

- **Status da Validacao do Bug**: `[BUG CONFIRMADO]` | `[PARCIALMENTE PROCEDENTE / RISCO MITIGADO]`
- **Classificacao de Risco Original**: `[RISCO ALTO]` | `[RISCO MEDIO]` | `[RISCO BAIXO]` | `[FORA DO ESCOPO]`
- **Classificacao de Risco Reavaliada**: `[RISCO ALTO]` | `[RISCO MEDIO]` | `[RISCO BAIXO]` | `[RISCO NULO]` | `[FORA DO ESCOPO]`
- **Localizacao**: [link da linha no arquivo da branch]

#### 1. Descricao do Apontamento
[Causa raiz, pre-condicoes, cenario de falha, impacto e principio/contrato violado.]

#### 2. Analise Defensiva e Veredito Tecnico
[Garantias de fluxo, tratamentos upstream, comportamento de engine/framework e dados de runtime examinados; explique objetivamente por que neutralizam, mitigam ou nao impedem o problema.]

#### 3. Proposta de Alteracao
```php
// Antes: trecho minimo que evidencia o problema

// Depois: uma correcao possivel, compativel com a stack
```

#### 4. Orientacao para o Tech Lead
- **O bug procede?**: `Sim` | `Parcialmente`
- **Recomendacao**: [correcao necessaria, ajuste de severidade ou decisao de escopo]
````

Se a correcao nao couber honestamente em um trecho antes/depois, substitua o bloco por passos tecnicos concretos e explique por que um patch isolado seria enganoso.

## Hipoteses Refutadas

Falsos positivos nao entram na lista de issues. Quando for util registrar a refutacao, use uma tabela curta:

| Hipotese | Evidencia defensiva | Veredito |
|---|---|---|
| ... | ... | `[FALSO POSITIVO]` |

## Links

Quando o remote corresponder ao servidor Cafe/Vendpago, use:

```text
https://cafe.erpvending.com.br/Vendpago/<projeto>/src/branch/<branch>/<caminho>#L<linha>
```

Codifique corretamente nomes de branch e caminhos. A linha deve ser a linha atual do arquivo, nao a linha exibida no diff. Para outro servidor, derive o formato do remote real. Se nao houver remote ou branch verificavel, use `caminho#Llinha` e informe a limitacao.

## Veredito e Evidencias

Feche o parecer com:

- matriz de DoD;
- matriz do percurso de `pullrequest.md`;
- comandos e testes executados;
- evidencias de navegador, quando aplicaveis;
- limitacoes e itens bloqueados;
- decisao `APROVAR`, `SOLICITAR ALTERACOES` ou `BLOQUEADO`.

Nao use ausencia de achados como prova de que testes passaram. Nao use testes verdes como prova de ausencia de falhas de seguranca, arquitetura ou escopo.
