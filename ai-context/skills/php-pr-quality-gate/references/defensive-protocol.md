# Protocolo de Revisao Defensiva

O contraditorio e obrigatorio para cada hipotese levantada pela primeira revisao. Seu papel e reduzir falsos positivos, nao proteger a implementacao a qualquer custo.

## Ficha por Hipotese

Registre internamente:

- alegacao original;
- pre-condicoes necessarias para a falha;
- entrada ou evento que aciona o caminho;
- causa raiz no codigo;
- impacto observavel;
- evidencia de linha e codigo adjacente;
- testes capazes de confirmar ou refutar.

## Tentativa de Refutacao

Inspecione explicitamente:

1. **Garantias de fluxo e dominio:** casts, validacoes anteriores, cardinalidade limitada, constraints, invariantes e caminhos inalcançaveis.
2. **Tratamentos envolventes:** chamadores, `try-catch`, error handlers do Zend, wrappers transacionais, rollback e normalizacao anterior.
3. **Engine e framework:** semantica da versao correta do PHP/PostgreSQL, lifecycle do Zend 1.x, autoescape ou modificadores Smarty e comportamento do driver.
4. **Persistencia real:** schema, indices, foreign keys, triggers, defaults e isolamento da transacao, quando acessiveis.
5. **Trade-off intencional:** limites documentados no escopo, volume maximo comprovado e compatibilidade retroativa necessaria.

Uma defesa e valida somente se estiver comprovada no codigo, schema, configuracao, documentacao versionada ou execucao observada. Possibilidades abstratas como "talvez exista validacao upstream" nao refutam nada.

## Casos Frequentes

- SQL concatenado apos `(int)`, `intval()` ou enum interna comprovada nao e automaticamente SQL injection; confirme que nenhum caminho evita a conversao.
- Smarty sem `|escape` pode estar seguro se o valor for constante, numerico ou escapado corretamente antes, mas escape precoce e contexto incorreto podem continuar vulneraveis.
- Escrita isolada em uma tabela pode nao exigir transacao explicita; escritas correlacionadas exigem verificar uma transacao externa antes de apontar falha.
- Uma query dentro de loop pequeno e estritamente limitado pode ser trade-off aceitavel; prove o limite real e avalie custo antes de chamar N+1 bloqueante.
- Recursos aparentemente nao inicializados podem vir de bootstrap, plugin, registry ou action helper do Zend.
- Redirecionamento imediato nao prova protecao contra double submit: verifique se duas requisicoes podem sair antes da navegacao.

## Veredito

- `BUG CONFIRMADO`: nenhuma garantia neutraliza o cenario, e a evidencia liga causa a impacto.
- `FALSO POSITIVO`: uma garantia concreta torna o cenario impossivel ou inofensivo.
- `PARCIALMENTE PROCEDENTE / RISCO MITIGADO`: existe falha ou fragilidade, mas protecao concreta reduz alcance, probabilidade ou impacto.

Reavalie a severidade depois da defesa. Explique no parecer a garantia testada e por que ela falhou ou mitigou o risco. Exponha evidencia e conclusao concisas; nao apresente raciocinio privado ou especulacao como fato.
