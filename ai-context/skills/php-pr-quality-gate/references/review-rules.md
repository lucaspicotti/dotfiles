# Regras de Revisao PHP Legada

## Matriz do Projeto

Identifique o projeto por evidencia do repositorio. Nao presuma a stack apenas pelo diretorio atual.

| Projeto | PHP | PostgreSQL | Pontos especificos |
|---|---:|---:|---|
| Erp | 7.4 | 14.24 | Zend 1.x, Smarty, JS Vanilla e multiplos schemas/aliases: `erp`, `vendtef`, `micromarket`, `payblu` |
| VendTef | 7.4 | 14.24 | Isolamento multi-operador por `dbName`/`dbHost`; impedir acesso cruzado; MD5 proibido em novos fluxos de senha |
| MicroMarket | 7.0 | 9.4.26 | Proibir recursos PHP 7.1+ e SQL posterior ao PostgreSQL 9.4, inclusive `ON CONFLICT` |
| PayBlu | 7.4 | 14.24 | Transacoes financeiras e conexoes adicionais a multiplos bancos/esquemas |

Todos usam Zend Framework 1.x, Smarty Templates e JavaScript Vanilla, salvo evidencia versionada em contrario.

## Ordem de Inspecao

1. Entenda `escopo.md`, `pullrequest.md`, os testes alterados e o comportamento esperado.
2. Determine o diff correto e enumere arquivos adicionados, removidos, renomeados e alterados.
3. Leia os testes antes da implementacao. Verifique se testam comportamento e se falhariam diante da regressao alegada.
4. Inspecione a implementacao e o codigo adjacente: chamadores, controladores, models, helpers, bootstrap, views Smarty, JavaScript e SQL relacionado.
5. Revise configuracoes, migrations/publicacoes, indices e lockfiles quando afetados.

## Eixos Obrigatorios

### Correcao e escopo

- Compare cada mudanca com requisito e DoD, incluindo vazio, `null`, limites e caminhos de erro.
- Procure divergencias silenciosas de estado, off-by-one, perda de dados e concorrencia.
- Marque como fora do escopo apenas mudanca real sem justificativa funcional; nao confunda codigo adjacente necessario com expansao indevida.

### Compatibilidade

- Em PHP 7.4, rejeite recursos PHP 8+, como `match`, `?->`, union types, named arguments, constructor property promotion, enums e `str_contains`.
- Em PHP 7.0, rejeite recursos 7.1+, como `void`, nullable types, `iterable`, multi-catch e visibilidade de constantes de classe.
- No MicroMarket, rejeite sintaxe ou funcoes do PostgreSQL posteriores a 9.4.
- Confirme comportamento real do Zend 1.x e Smarty antes de alegar incompatibilidade.

### Seguranca

- Rastreie dados nao confiaveis ate SQL, HTML, logs, filesystem e comandos.
- Confirme parametrizacao SQL; casts numericos ou constantes internas podem neutralizar injecao, mas precisam estar no caminho efetivo.
- Confirme escape no ponto correto de saida Smarty e tokens CSRF em escritas sensiveis.
- Verifique autenticacao, autorizacao, isolamento multi-operador e ausencia de PII, tokens e senhas em logs.
- Em VendTef, valide `dbName`, `dbHost` e `oid` no backend. Nao aceite MD5 em novos fluxos de autenticacao.

### Dados, concorrencia e performance

- Procure N+1, consultas sem limite, falta de paginacao e `WHERE`/`JOIN`/`ORDER BY` sem indice plausivel.
- Verifique atomicidade de escritas correlacionadas, rollback e efeitos de excecoes entre etapas.
- Em fluxos financeiros ou concorrentes, inspecione idempotencia, locks, nivel de isolamento e dupla submissao.
- Nao confirme falta de indice sem verificar schema, publicacoes/migrations ou metadados acessiveis.

### Arquitetura e manutencao

- Avalie limites de modulo, SRP, duplicacao, tipos, acoplamento e complexidade resultante.
- Prefira remedios que removam branches ou pecas moveis a wrappers que apenas realocam complexidade.
- Identifique codigo morto, debug local, recursos nao fechados e dependencias novas desnecessarias.
- Diferencie defeito operacional de preferencia de estilo. PSR e nit nao devem mascarar bugs reais.

### Frontend

- Verifique double submit, requisicoes concorrentes, handlers ativos em elementos invisiveis e tratamento de falhas assincronas.
- Dados dinamicos em Smarty devem ser escapados conforme o contexto.
- Novos estilos devem seguir a convencao SCSS do projeto; sinalize CSS bruto ou inline quando vetado.
- UI alterada precisa de validacao de DOM, console, rede, estado visual e acessibilidade proporcional ao escopo.

## Severidade

- `[RISCO ALTO]`: fatal error, quebra central, SQL injection, XSS/CSRF critico, acesso indevido, PII, corrupcao/perda transacional ou incompatibilidade de runtime.
- `[RISCO MEDIO]`: divergencia funcional, concorrencia de UI, N+1/falta de indice demonstravel ou degradacao arquitetural com impacto claro.
- `[RISCO BAIXO]`: codigo morto, desvio de padrao ou melhoria pequena com baixo impacto operacional.
- `[FORA DO ESCOPO]`: comportamento adicionado ou alterado sem relacao necessaria com a demanda e que introduz risco.

Se a evidencia nao sustentar impacto e cenario concreto, nao publique como bug.
