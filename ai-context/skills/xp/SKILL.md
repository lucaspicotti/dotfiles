---
name: xp
description: Programação Extrema adaptada para o desenvolvimento em dupla entre IA e humano. Use sempre que o usuário quiser trabalhar de forma estruturada e iterativa com seu agente de IA — mencionar XP, Extreme Programming, programação em par (pair programming), ágil, YAGNI, design simples, refatoração contínua ou desejar planejar antes de programar. Utilize também quando o usuário quiser desenvolver funcionalidades de forma incremental, com testes, ciclos de feedback e divisão clara de responsabilidades entre humano e IA. Esta skill representa a evolução da programação em par na era da IA.
---

# XP — Extreme Programming com Agentes de IA

## Filosofia

O Extreme Programming (XP) leva boas práticas de engenharia de software ao extremo. Revisões de código tornam-se *contínuas* (pair programming). Testes tornam-se *incansáveis* (TDD). A melhoria do design torna-se *constante* (refatoração). O planejamento torna-se *frequente* (pequenas entregas).

Com agentes de IA, o XP evolui ainda mais. A IA não se cansa, não perde o foco e pode revisar cada linha de código à medida que ela é escrita. Já o ser humano contribui com julgamento, conhecimento do domínio e a capacidade de dizer "não". A dupla — humano + IA — é mais poderosa do que qualquer um dos dois isoladamente, mas apenas quando trabalham juntos com papéis bem definidos e valores compartilhados.

Esta skill define a metodologia que orienta a colaboração entre você e seu agente de IA. Ela não é uma ferramenta nem um framework — é uma disciplina.

## Os Cinco Valores

Esses valores são a base do XP. Toda prática e toda decisão de fluxo de trabalho derivam deles.

### Comunicação

No XP tradicional, os desenvolvedores se comunicam constantemente. Com um agente de IA, comunicação significa:

- **Compartilhe o contexto de forma explícita.** A IA não conhece seu modelo mental. Explique o que está sendo desenvolvido, por quê e como será considerado concluído antes de começar.
- **Leia antes de escrever.** Sempre compreenda a base de código existente antes de propor alterações. A IA deve explorar a estrutura do projeto, ler os arquivos relevantes e entender os padrões utilizados.
- **Pergunte, não presuma.** Quando os requisitos não estiverem claros, pergunte ao usuário. Uma dúvida de 30 segundos evita uma implementação errada de 30 minutos.
- **Explique seu raciocínio.** Quando a IA tomar uma decisão, deve explicar por que a tomou, e não apenas o que fez. Isso permite que o usuário corrija a direção quando necessário.

### Simplicidade

O princípio YAGNI (*You Aren't Gonna Need It* — "Você não vai precisar disso"). Talvez esta seja a prática mais importante ao trabalhar com IA, pois agentes de IA são *excelentes em gerar código* e podem facilmente criar soluções excessivamente complexas se não forem orientados.

- **Construa apenas o que é necessário hoje.** Não adicione "flexibilidade" para um futuro que talvez nunca exista.
- **Um teste, uma implementação.** Cada ciclo deve representar a menor unidade possível de progresso.
- **Apague código sem medo.** Se algo não é utilizado, remova. A IA deve sugerir eliminar código morto, e não apenas adicionar novo código.
- **A solução mais simples que funciona.** Antes de propor algo sofisticado, pergunte: uma abordagem direta resolve? Na maioria das vezes, sim.

### Feedback

Kent Beck disse:

> "O otimismo é um risco ocupacional da programação. O feedback é o tratamento."

- **Execute testes e lint após cada alteração.** Sem exceções. Se o projeto possui um comando de testes, execute-o. Se possui um linter, execute-o. Se houver dúvida, pergunte ao usuário.
- **Mostre, não apenas diga.** Quando a IA concluir uma tarefa, o usuário deve ver o resultado — execute o código, apresente a saída e demonstre que os testes passaram.
- **Mantenha ciclos curtos de feedback.** Cada ciclo deve ser curto o suficiente para que o usuário possa revisar e redirecionar o trabalho em minutos, não horas.
- **Valide suas suposições.** Se houver dúvida sobre uma API, um caminho de arquivo ou uma convenção do projeto, verifique antes de assumir.

### Coragem

Com um agente de IA, você pode ser mais ousado do que seria trabalhando sozinho.

- **Refatore sem medo.** A IA pode refatorar grandes trechos de código enquanto os testes garantem que o comportamento permaneça correto.
- **Descarte código ruim.** Se uma abordagem não estiver funcionando, elimine-a e recomece. Custos já investidos não devem influenciar a decisão.
- **Experimente.** A IA pode criar três protótipos no tempo em que uma pessoa desenvolveria apenas um. Aproveite isso para explorar alternativas.
- **Questione decisões.** Se a solicitação do usuário levar a um design ruim, a IA deve dizer isso de forma respeitosa, fundamentada e firme.

### Respeito

O respeito deve existir nos dois lados da parceria.

- **Siga as convenções do projeto.** Leia o código existente, mantenha seu estilo e utilize os padrões já adotados. Não imponha preferências externas.
- **Entenda antes de modificar.** Nunca altere código que você não leu. Nunca proponha mudanças arquiteturais sem antes compreender a estrutura existente.
- **Respeite o tempo do usuário.** Não gere grandes blocos de código sem explicação. Não execute comandos demorados sem perguntar. Não faça commits sem autorização.
- **Preserve a intenção original.** Durante uma refatoração, o comportamento deve permanecer exatamente o mesmo. O código deve ficar mais claro, não apenas diferente.

## Fluxo de Trabalho

### 1. Planejar — Defina uma Pequena Tarefa

Escolha a menor unidade de trabalho possível que entregue valor. Escreva um objetivo claro e específico.

```text
Ruim:  "Adicionar autenticação"
Bom:   "Criar um endpoint de login que receba e-mail e senha e retorne um JWT"
```

Antes de começar, confirme com o usuário:

- Como será considerado que a tarefa está concluída?
- Quais comportamentos são mais importantes?
- Existem restrições ou convenções que devem ser seguidas?

### 2. Testar — Escreva um Teste

Escreva um único teste que descreva o comportamento esperado. O teste deve falhar — isso confirma que você está testando a funcionalidade correta. Utilize a skill **tdd** para seguir detalhadamente o ciclo vermelho-verde-refatoração.

```text
VERMELHO: Escreva um teste → o teste falha
```

### 3. Implementar — Código Mínimo para Passar

Escreva apenas o código necessário para que o teste passe. Nada além disso.

```text
VERDE: Implementação mínima → o teste passa
```

### 4. Refatorar — Melhorar Mantendo Tudo Verde

Agora que o teste passa, faça a limpeza do código. Procure por:

- Duplicações que possam ser extraídas.
- Nomes que possam ser mais claros.
- Estruturas que possam ser simplificadas.
- Oportunidades de abstração melhores (mas apenas se forem realmente necessárias agora).

Execute os testes após cada etapa da refatoração. Nunca refatore enquanto houver testes falhando.

```text
REFATORAÇÃO: Limpeza do código → todos os testes continuam passando
```

### 5. Entregar — Faça o Commit do Incremento

Realize um commit representando uma unidade coerente de trabalho. Commits pequenos, focados e com mensagens claras. Em seguida, escolha a próxima tarefa e repita o ciclo.

## Práticas Contínuas

Estas não são etapas do fluxo de trabalho — são hábitos que devem estar presentes durante toda a sessão.

- **Leia a base de código primeiro.** Antes de alterar qualquer coisa, explore o projeto. Utilize ferramentas como `glob`, `grep` e leitura de arquivos para entender o que já existe.
- **Execute lint e testes.** Após cada alteração relevante. Se o projeto possuir um comando de CI, utilize-o.
- **Siga as convenções.** Adote o mesmo estilo do código ao redor. Se existir uma configuração de linter, respeite-a.
- **Mantenha tarefas pequenas.** Se algo parecer grande demais, divida em partes menores. Cada ciclo deve durar minutos, não horas.
- **Comunique-se constantemente.** Explique o que está fazendo, por que escolheu determinada abordagem e quais são os trade-offs envolvidos.

## Referências

- [xp-practices](../praticas-xp/SKILL.md) — As 12 práticas do XP adaptadas para colaboração entre IA e humano.
- [roles.md](references/roles.md) — Papéis de Driver e Navigator, antipadrões e variações de programação em par.
- Utilize a skill [tdd](../tdd/SKILL.md) para seguir o fluxo detalhado de desenvolvimento orientado por testes.
