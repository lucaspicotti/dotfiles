---
name: tdd
description: Desenvolvimento Orientado a Testes adaptado para agentes de IA. Use quando o usuário quiser implementar funcionalidades guiadas por testes, corrigir bugs com testes de regressão, trabalhar com Red-Green-Refactor, melhorar testabilidade, criar testes antes da implementação ou desenvolver de forma incremental e segura.
---

# TDD — Desenvolvimento Orientado a Testes

## Filosofia

Test-Driven Development é uma disciplina de desenvolvimento em que os testes orientam o design e a implementação do software.

Os testes não devem ser tratados como uma etapa posterior de validação.

Os testes são a especificação executável do comportamento esperado.

O objetivo do TDD não é apenas aumentar a cobertura de testes. O objetivo é produzir código:

- mais simples;
- mais fácil de modificar;
- menos acoplado;
- mais previsível;
- continuamente validado.

O agente de IA deve usar os testes para descobrir o próximo menor passo de implementação.

---

# Regra Central

Toda alteração de comportamento deve seguir este ciclo:

```text
RED
↓
GREEN
↓
REFACTOR
↓
REPEAT
```

Nunca pule uma fase.

Nunca misture fases.

Trabalhe com apenas um comportamento por ciclo.

---

# As Três Leis do TDD

## Primeira Lei

Não escreva código de produção sem que exista um teste falhando que exija esse código.

## Segunda Lei

Não escreva mais código de teste do que o necessário para produzir uma falha significativa.

Erros de sintaxe, configuração ou carregamento não contam como uma falha válida de comportamento.

## Terceira Lei

Não escreva mais código de produção do que o necessário para fazer o teste atual passar.

---

# Comportamento do Agente

O agente atua como parceiro de TDD.

Em cada iteração, deve:

1. entender o comportamento solicitado;
2. identificar o menor incremento observável;
3. verificar os testes existentes relacionados;
4. escrever exatamente um teste que falhe;
5. confirmar que a falha ocorre pelo motivo esperado;
6. implementar o mínimo necessário;
7. executar o teste novamente;
8. executar a suíte de testes relevante;
9. refatorar somente com todos os testes passando;
10. repetir o ciclo para o próximo comportamento.

O agente não deve gerar a implementação completa antecipadamente.

---

# Fluxo de Trabalho

## 1. Entender o Comportamento

Antes de escrever código, identifique:

- o comportamento esperado;
- a entrada;
- a saída;
- as regras de negócio;
- os efeitos colaterais;
- os casos de erro;
- os limites do escopo;
- os contratos existentes.

Quando houver código existente, leia primeiro:

- os testes relacionados;
- a implementação atual;
- as interfaces envolvidas;
- os pontos de integração;
- as convenções do projeto.

Não altere código antes de entender o comportamento observável.

---

## 2. Escolher o Menor Incremento

Divida a funcionalidade em pequenos comportamentos independentes.

Prefira começar pelo caso mais simples.

Exemplo:

```text
Funcionalidade: aplicar desconto em um pedido

1. pedido sem desconto mantém o valor original;
2. desconto percentual reduz o total;
3. desconto não pode gerar total negativo;
4. desconto inválido deve ser rejeitado.
```

Implemente um item por vez.

Não tente cobrir todos os casos em um único ciclo.

---

## 3. RED — Escrever um Teste que Falha

Escreva um teste para o próximo comportamento ainda não implementado.

O teste deve ser:

- pequeno;
- legível;
- determinístico;
- independente;
- focado em um comportamento;
- capaz de falhar por uma razão clara.

Use nomes que descrevam o comportamento.

Bom:

```text
deve_retornar_total_original_quando_nao_houver_desconto
```

Ruim:

```text
teste_calculo
```

Depois de escrever o teste:

1. execute-o;
2. confirme que ele falha;
3. confirme que a mensagem de falha representa o comportamento ausente.

Se o teste passar antes da implementação, investigue:

- o comportamento já existe;
- o teste não está exercitando o código correto;
- a asserção está fraca;
- o teste está configurado incorretamente.

Não avance para GREEN sem uma falha válida.

---

## 4. GREEN — Implementar o Mínimo Necessário

Escreva apenas o código necessário para fazer o teste atual passar.

Durante GREEN:

- prefira soluções simples;
- aceite implementações provisórias quando forem suficientes;
- evite abstrações prematuras;
- não implemente casos futuros;
- não otimize sem necessidade;
- não refatore código não relacionado;
- não adicione comportamentos sem teste.

YAGNI deve ser aplicado.

Uma solução simples é preferível a uma arquitetura genérica que ainda não foi exigida pelos testes.

Depois da implementação:

1. execute o teste novo;
2. confirme que ele passa;
3. execute os testes relacionados;
4. execute a suíte completa quando for viável.

Não avance para REFACTOR enquanto houver falhas.

---

## 5. REFACTOR — Melhorar sem Alterar Comportamento

Refatore somente quando todos os testes estiverem passando.

Durante a refatoração, você pode:

- melhorar nomes;
- remover duplicação;
- extrair métodos;
- simplificar condicionais;
- reduzir acoplamento;
- melhorar coesão;
- reorganizar responsabilidades;
- remover código morto;
- tornar dependências explícitas.

Durante a refatoração, você não pode:

- adicionar novo comportamento;
- alterar regras de negócio;
- ampliar o escopo;
- corrigir outro problema sem teste;
- mudar contratos sem necessidade.

Execute os testes após cada pequena alteração.

A refatoração está concluída quando o código está mais claro e o comportamento permanece inalterado.

---

# Estrutura dos Testes

Prefira a estrutura Arrange, Act, Assert.

```text
Arrange
Preparar os dados e dependências.

Act
Executar o comportamento testado.

Assert
Verificar o resultado observável.
```

Exemplo conceitual:

```php
public function test_deve_calcular_total_com_desconto(): void
{
    // Arrange
    $pedido = new Pedido(100);

    // Act
    $total = $pedido->aplicarDescontoPercentual(10);

    // Assert
    $this->assertSame(90.0, $total);
}
```

Evite comentários quando o código já expressar claramente as três etapas.

---

# Características de um Bom Teste

Todo teste deve ser:

## Determinístico

O mesmo teste deve produzir o mesmo resultado em todas as execuções.

Evite dependência de:

- horário atual;
- dados aleatórios;
- ordem de execução;
- rede;
- estado externo não controlado.

## Independente

Um teste não deve depender da execução de outro teste.

Cada teste deve preparar e limpar seu próprio estado.

## Rápido

Testes unitários devem executar rapidamente.

Separe testes lentos de integração ou ponta a ponta quando necessário.

## Legível

O teste deve comunicar a regra de negócio.

Um leitor deve entender o comportamento esperado sem precisar examinar toda a implementação.

## Focado

Cada teste deve representar um comportamento ou cenário específico.

Múltiplas asserções são aceitáveis quando verificam o mesmo comportamento observável.

## Confiável

Um teste não pode falhar de forma intermitente.

Testes instáveis devem ser corrigidos, não ignorados.

---

# Testar Comportamento, Não Implementação

Prefira testar resultados observáveis.

Teste:

- valores retornados;
- mudanças de estado;
- eventos emitidos;
- erros esperados;
- interações externas relevantes;
- contratos públicos.

Evite testar:

- métodos privados;
- ordem interna sem relevância de negócio;
- detalhes de algoritmo;
- estrutura interna de objetos;
- chamadas intermediárias sem significado observável.

Um teste excessivamente acoplado à implementação dificulta a refatoração.

---

# Dublês de Teste

Use dublês quando uma dependência externa tornar o teste:

- lento;
- não determinístico;
- difícil de configurar;
- dependente de infraestrutura;
- sujeito a efeitos colaterais.

## Stub

Fornece respostas controladas.

Use quando o teste precisa receber dados previsíveis de uma dependência.

## Mock

Verifica uma interação relevante.

Use somente quando a chamada realizada faz parte do comportamento observável.

## Fake

Implementa uma versão simplificada e funcional da dependência.

Exemplo: repositório em memória.

## Spy

Registra chamadas para verificação posterior.

Evite mocks excessivos.

Muitos mocks podem indicar:

- alto acoplamento;
- responsabilidades mal separadas;
- teste focado na implementação;
- design difícil de usar.

---

# Banco de Dados e Serviços Externos

Testes unitários não devem depender de banco de dados real, rede ou APIs externas.

Para esses casos, prefira:

- interfaces;
- adaptadores;
- repositórios em memória;
- fakes;
- stubs;
- fixtures controladas.

Use testes de integração quando for necessário validar:

- consultas SQL;
- mapeamentos;
- transações;
- constraints;
- integração com framework;
- comportamento real do banco;
- serialização;
- contratos entre componentes.

Não substitua todo teste de integração por mocks.

Teste a integração real nos limites onde ela importa.

---

# Correção de Bugs

Toda correção de bug deve começar com um teste de regressão.

Fluxo obrigatório:

1. reproduzir o bug;
2. escrever um teste que demonstre o comportamento incorreto;
3. executar o teste e confirmar a falha;
4. implementar a menor correção;
5. executar o teste novamente;
6. executar os testes relacionados;
7. refatorar se necessário.

Nunca corrija um bug sem preservar sua reprodução em um teste, salvo quando tecnicamente impossível.

---

# Código Legado sem Testes

Ao alterar código legado:

1. identifique o comportamento atual;
2. crie testes de caracterização;
3. confirme que os testes representam o estado existente;
4. isole dependências quando necessário;
5. escreva um teste para a nova alteração;
6. faça a menor mudança possível;
7. refatore gradualmente.

Testes de caracterização não afirmam que o comportamento atual está correto.

Eles registram o comportamento existente para permitir mudanças seguras.

---

# Escolha do Tipo de Teste

Use o menor nível de teste capaz de validar o comportamento com confiança.

## Teste Unitário

Use para regras de negócio isoladas, cálculos, validações e transformações.

## Teste de Integração

Use para validar a colaboração real entre componentes, banco, framework, filas ou serviços.

## Teste de Contrato

Use para validar formatos e acordos entre sistemas ou módulos.

## Teste Ponta a Ponta

Use para fluxos críticos completos.

Não tente validar toda regra de negócio apenas com testes ponta a ponta.

Prefira uma base maior de testes rápidos e poucos testes amplos.

---

# Estratégias de Implementação

Durante GREEN, o agente pode usar estratégias incrementais.

## Fake It

Retorne uma resposta fixa para fazer o primeiro teste passar.

Depois, generalize quando um novo teste exigir.

## Triangulação

Adicione exemplos diferentes para impedir uma solução excessivamente específica.

## Implementação Óbvia

Quando a solução mínima for simples e clara, implemente diretamente.

Mesmo com implementação óbvia, o teste deve falhar primeiro.

---

# Regras de Escopo

Cada ciclo deve tratar apenas um comportamento.

Não faça durante o mesmo ciclo:

- mudanças de arquitetura não exigidas;
- formatação ampla do projeto;
- atualização de dependências;
- correções paralelas;
- renomeações não relacionadas;
- otimizações especulativas.

Quando outro problema for encontrado:

1. registre-o;
2. mantenha o foco no ciclo atual;
3. trate-o em outro teste e outra alteração.

---

# Anti-Padrões

Nunca:

- escreva a implementação completa antes dos testes;
- escreva testes apenas depois de terminar;
- pule RED porque a solução parece óbvia;
- altere teste e produção ao mesmo tempo sem validar a falha;
- faça vários comportamentos passarem de uma vez;
- enfraqueça uma asserção apenas para obter GREEN;
- remova um teste válido porque ele falha;
- use mocks para todos os colaboradores;
- teste métodos privados diretamente;
- dependa da ordem dos testes;
- use `sleep` para sincronização;
- acesse serviços externos em testes unitários;
- refatore enquanto houver testes falhando;
- aumente o escopo sem um teste que exija isso;
- confunda cobertura alta com boa qualidade.

---

# Quando Não Aplicar TDD Rigidamente

TDD pode ser reduzido temporariamente em:

- exploração técnica;
- protótipos descartáveis;
- investigação de APIs desconhecidas;
- spikes;
- experimentos sem comportamento definido;
- scripts realmente temporários.

Nesses casos:

1. deixe claro que o código é exploratório;
2. não trate o protótipo como produção;
3. descarte ou reestruture a solução;
4. retorne ao TDD quando o comportamento estiver compreendido.

Código exploratório que se tornar permanente deve receber testes antes de evoluir.

---

# Tomada de Decisão

```text
Existe um novo comportamento?
    ↓
Escolha o menor exemplo observável.
    ↓
Escreva um teste.
    ↓
O teste falhou pelo motivo esperado?
    ├── Não → corrija o teste ou investigue o comportamento existente.
    └── Sim
         ↓
Implemente o mínimo necessário.
         ↓
O teste passou?
    ├── Não → ajuste apenas o necessário.
    └── Sim
         ↓
Os testes relacionados passaram?
    ├── Não → corrija a regressão.
    └── Sim
         ↓
Há melhoria estrutural segura?
    ├── Sim → refatore e execute os testes.
    └── Não → inicie o próximo ciclo.
```

---

# Forma de Comunicação do Agente

Ao trabalhar com TDD, o agente deve comunicar claramente:

## Antes do RED

- qual comportamento será testado;
- por que ele é o menor próximo passo;
- qual arquivo de teste será alterado.

## Depois do RED

- qual teste foi criado;
- qual falha ocorreu;
- por que a falha é esperada.

## Depois do GREEN

- qual implementação mínima foi adicionada;
- quais testes foram executados;
- quais testes passaram.

## Depois do REFACTOR

- o que foi melhorado;
- por que o comportamento não mudou;
- quais testes confirmam a segurança da alteração.

Não declare que um teste passou sem executá-lo.

Quando não for possível executar testes, diga explicitamente:

```text
Os testes não foram executados neste ambiente.
```

Não substitua execução real por suposição.

---

# Formato de Iteração

Use este formato durante o desenvolvimento:

```md
## Iteração

### Comportamento
Descrever o comportamento sendo implementado.

### RED
Descrever o teste criado e a falha esperada.

### GREEN
Descrever a implementação mínima.

### REFACTOR
Descrever as melhorias estruturais, se houver.

### Validação
Listar os testes executados e seus resultados.

### Próximo passo
Indicar o próximo menor comportamento ainda não implementado.
```

---

# Critérios de Conclusão

Uma alteração está concluída quando:

- o comportamento solicitado está coberto;
- cada novo comportamento foi guiado por um teste;
- testes de regressão foram adicionados para bugs;
- todos os testes relevantes passam;
- nenhuma falha foi ignorada;
- o código foi refatorado quando necessário;
- não existe implementação especulativa;
- o design está simples para os requisitos atuais;
- a intenção do código está clara;
- o agente informou quais testes foram realmente executados.

---

# Princípios Finais

Tests are the specification.

Teste primeiro.

Implemente o mínimo.

Refatore com segurança.

Trabalhe em pequenos passos.

Não antecipe requisitos.

Não afirme resultados que não foram verificados.

Quando estiver em dúvida, escreva o próximo menor teste.
