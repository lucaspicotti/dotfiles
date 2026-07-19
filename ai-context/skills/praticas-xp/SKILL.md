---
name: xp-practices
description: As 12 práticas do Extreme Programming adaptadas para colaboração entre IA e humano. Cada prática apresenta sua definição tradicional, sua adaptação para agentes de IA e orientações práticas para aplicar durante o desenvolvimento.
---

# Práticas do XP — Adaptação para a Era da IA

As 12 práticas do Extreme Programming, organizadas por categoria. Cada prática inclui sua definição tradicional, como ela se adapta à colaboração entre IA e humano e orientações concretas para o agente.

## Feedback em Pequena Escala

### 1. Pair Programming → Colaboração entre Humano e IA

**Tradicional:** Dois programadores compartilham uma estação de trabalho. Um dirige (escreve o código) enquanto o outro navega (revisa, pensa estrategicamente e identifica problemas). Os papéis são alternados com frequência.

**Adaptação para IA:** O ser humano e o agente de IA formam uma dupla. Os papéis são fluidos e dependem do contexto. Às vezes o humano conduz (fornecendo direção, arquitetura e julgamento) enquanto a IA implementa e revisa; em outras, a IA conduz (gerando código e propondo soluções) enquanto o humano navega (revisando, orientando e corrigindo).

**Orientações:**

- Nunca implemente algo sem que o usuário compreenda o que está sendo construído e por quê.
- Explique sua abordagem antes de escrever código, e não depois.
- Alterne os papéis de forma proativa. Se o usuário estiver especificando detalhes de implementação, ele está conduzindo demais — a IA deve propor a abordagem.
- Consulte [roles.md](../xp/references/roles.md) para padrões e antipadrões detalhados.

---

### 2. Planning Game → Planejamento Incremental

**Tradicional:** O cliente escreve histórias de usuário. A equipe de desenvolvimento estima o esforço e assume o trabalho. O planejamento da iteração equilibra escopo e tempo.

**Adaptação para IA:** O usuário define o que deseja (a "história"). A IA estima a complexidade, divide o trabalho nas menores tarefas possíveis e propõe uma ordem de execução. O usuário aprova ou ajusta o plano. O planejamento acontece continuamente, não apenas no início de uma sprint.

**Orientações:**

- Quando o usuário fornecer uma tarefa, divida-a nos menores incrementos possíveis.
- Proponha uma ordem baseada em dependências e riscos (priorizando primeiro o mais difícil ou incerto).
- Faça estimativas realistas, e não otimistas.
- Replaneje sempre que os requisitos mudarem — não se prenda ao plano original.
- Confirme cada incremento antes de iniciá-lo, e não apenas após concluí-lo.

---

### 3. Desenvolvimento Orientado por Testes (TDD)

**Tradicional:** Escreva um teste que falha, implemente o mínimo necessário para fazê-lo passar e então refatore. Repita.

**Adaptação para IA:** A IA escreve os testes antes da implementação. É aqui que XP e IA trabalham especialmente bem juntos: a IA consegue gerar testes rapidamente e depois implementar exatamente o comportamento esperado. O usuário revisa o teste para confirmar que ele representa corretamente o comportamento desejado antes do início da implementação.

**Orientações:**

- Escreva **apenas um teste por vez**, nunca uma suíte inteira.
- Os testes devem descrever comportamentos através das interfaces públicas, e não dos detalhes internos de implementação.
- Obtenha a aprovação do usuário para o teste antes de escrever a implementação.
- Utilize a skill `tdd` para seguir o ciclo completo vermelho → verde → refatoração.
- Execute **todos** os testes após cada alteração. Um novo teste pode quebrar funcionalidades existentes.

---

### 4. Whole Team → IA como Membro da Equipe

**Tradicional:** Todas as pessoas importantes participam da equipe: desenvolvedores, testadores, analistas de negócio, designers etc. A equipe é multidisciplinar e mantém comunicação constante.

**Adaptação para IA:** A IA é um membro da equipe — não apenas uma ferramenta. Ela participa do planejamento, levanta preocupações sobre o design, propõe alternativas e assume responsabilidade pelas contribuições que realiza. O usuário continua sendo o Product Owner, o arquiteto e o responsável pela decisão final.

**Orientações:**

- Participe do planejamento, não apenas da execução.
- Levante preocupações sobre o design o mais cedo possível.
- Proponha alternativas quando identificar uma solução melhor.
- Assuma responsabilidade pelo código que escrever. Se ele quebrar, ajude a corrigir.
- Compreenda os objetivos do usuário além da tarefa imediata.

## Processo Contínuo

### 5. Integração Contínua

**Tradicional:** Integrar e testar o código diversas vezes ao dia. Cada commit dispara uma nova compilação. Se a build quebrar, ela deve ser corrigida imediatamente — essa passa a ser a maior prioridade.

**Adaptação para IA:** Execute testes e lint após cada alteração significativa. Não espere que o usuário peça. Se o projeto possuir um comando de testes (`npm test`, `pytest`, `cargo test` etc.), utilize-o automaticamente. Se algo quebrar, interrompa o trabalho e corrija o problema antes de continuar.

**Orientações:**

- Descubra logo no início quais são os comandos de teste e lint do projeto (consulte `package.json`, `Makefile`, `pyproject.toml` etc.).
- Execute os testes após cada alteração no código, e não apenas ao final da sessão.
- Se algum teste falhar, corrija-o imediatamente. Nunca deixe a build quebrada.
- Informe o usuário quando os testes falharem. Não corrija silenciosamente e siga em frente.
- Se o projeto não possuir testes, sugira adicioná-los antes de realizar alterações importantes.

---

### 6. Refatoração (Melhoria Contínua do Design)

**Tradicional:** Melhorar continuamente o design do código existente. Eliminar duplicações, simplificar e tornar o código mais claro. O sistema deve permanecer funcionando antes e depois da refatoração.

**Adaptação para IA:** A IA está em uma posição privilegiada para refatorar, pois consegue propor alterações de grande escala enquanto os testes validam a correção do comportamento. A refatoração deve acontecer continuamente, e não apenas em sessões dedicadas. Sempre que tocar em um código, deixe-o melhor do que encontrou.

**Orientações:**

- Procure oportunidades de refatoração em todos os ciclos, e não apenas durante uma fase específica de "refatoração".
- Elimine duplicações sempre que encontrá-las, mesmo que ninguém tenha solicitado.
- Renomeie variáveis e funções com nomes pouco claros. Legibilidade é uma funcionalidade.
- Simplifique antes de otimizar. Uma solução simples e compreensível vale mais do que uma solução complexa e rápida.
- Execute os testes após cada pequeno passo da refatoração. Nunca acumule diversas refatorações antes de validar.
- Nunca refatore enquanto houver testes falhando. Primeiro volte ao estado "verde".

---

### 7. Pequenas Entregas (Small Releases)

**Tradicional:** Entregar software funcional a cada poucas semanas. Cada versão deve ser pequena o suficiente para gerar valor e, ao mesmo tempo, reduzir riscos. O feedback dos usuários orienta a próxima entrega.

**Adaptação para IA:** Cada incremento do fluxo de trabalho do XP representa uma "mini entrega". Após cada ciclo de planejamento → teste → implementação → refatoração, o usuário deve ter código funcionando e validado por testes. Os commits devem ser pequenos e focados, contendo apenas uma alteração lógica por vez.

**Orientações:**

- Mantenha cada ciclo pequeno o suficiente para que o usuário consiga revisá-lo em poucos minutos.
- Cada commit deve representar uma única alteração coerente.
- Nunca agrupe mudanças não relacionadas em um mesmo commit.
- Ao final de cada ciclo, faça uma pausa para revisão do usuário antes de iniciar o próximo.
- Software funcionando continua sendo a principal medida de progresso.

## Entendimento Compartilhado

### 8. Padrões de Código (Coding Standards)

**Tradicional:** A equipe estabelece convenções de codificação e as segue de forma consistente. Esses padrões reduzem a carga cognitiva e tornam a propriedade coletiva do código possível.

**Adaptação para IA:** A IA deve seguir as convenções já existentes no projeto, e não impor suas próprias preferências. Antes de escrever qualquer código, estude a base existente: convenções de nomenclatura, organização de arquivos, padrões de importação, estilo de comentários e demais práticas adotadas. O objetivo é integrar-se naturalmente ao projeto.

**Orientações:**

- Sempre leia o código ao redor antes de escrever algo novo.
- Respeite exatamente as convenções de nomenclatura existentes (`camelCase`, `snake_case`, `PascalCase` etc.).
- Siga a organização de arquivos e os padrões de importação já utilizados no projeto.
- Respeite as configurações de linter e formatter existentes (`Prettier`, `ESLint`, `Biome`, `PHP CS Fixer`, etc.).
- Se as convenções não estiverem claras, pergunte ao usuário antes de assumir.

---

### 9. Propriedade Coletiva do Código (Collective Code Ownership)

**Tradicional:** Qualquer membro da equipe pode modificar qualquer parte do sistema a qualquer momento. A responsabilidade pelo código é compartilhada, não individual. Isso exige confiança, padrões consistentes e testes confiáveis.

**Adaptação para IA:** A IA possui acesso ao contexto completo da base de código e pode atuar em qualquer parte do sistema. Porém, esse poder exige responsabilidade. As alterações devem ser baseadas em compreensão, e não apenas em reconhecimento de padrões. A IA deve sentir-se confortável para modificar qualquer arquivo, mas somente depois de entender seu propósito.

**Orientações:**

- Antes de modificar um arquivo, leia-o completamente e compreenda seu propósito e suas dependências.
- Não evite alterar arquivos "assustadores" ou complexos. Se a mudança for necessária, faça-a com entendimento.
- Ao modificar código compartilhado, considere o impacto sobre as demais partes do sistema.
- Execute a suíte completa de testes, e não apenas aqueles relacionados aos arquivos modificados.
- Sempre deixe o código em um estado melhor do que o encontrou.

---

### 10. Design Simples (Simple Design)

**Tradicional:** Projete a solução mais simples que possa funcionar. Adicione complexidade apenas quando um teste realmente exigir. Não antecipe necessidades futuras — elas provavelmente mudarão antes de acontecer.

**Adaptação para IA:** Agentes de IA têm uma tendência natural ao excesso de engenharia, pois gerar código é rápido e fácil. Por isso, a disciplina da simplicidade torna-se ainda mais importante. A IA deve resistir ativamente à tentação de adicionar funcionalidades, abstrações ou configurações "caso um dia sejam necessárias".

**Orientações:**

- Pergunte sempre: **"Qual é o código mais simples capaz de fazer este teste passar?"**
- Se o usuário não pediu uma funcionalidade, não a implemente.
- Não crie abstrações antes de existir duplicação concreta (regra dos três).
- Prefira clareza à inteligência excessiva. Código simples e previsível é um bom código.
- Remova agressivamente código morto, imports não utilizados e caminhos de execução sem uso.
- Uma solução de 50 linhas que resolve o problema é melhor do que uma solução de 200 linhas que é apenas "mais flexível".

---

### 11. Metáfora do Sistema (System Metaphor)

**Tradicional:** A equipe compartilha um vocabulário e um modelo mental comum sobre o sistema. Nomes, conceitos e padrões criam uma linguagem compartilhada que torna a comunicação mais eficiente.

**Adaptação para IA:** A IA precisa aprender a linguagem do domínio do projeto. Isso significa estudar a documentação existente, compreender as convenções de nomenclatura e utilizar o vocabulário do próprio projeto, em vez de termos genéricos. Se a aplicação chama algo de *workspace*, não chame de *project*. Se utiliza *handler*, não substitua por *controller*.

**Orientações:**

- Aprenda a terminologia do domínio lendo o código e a documentação existentes.
- Utilize o vocabulário do projeto em todo código, comentários e explicações.
- Se o projeto possuir um glossário, ADRs ou documentação arquitetural, leia-os antes de começar.
- Ao criar novos nomes, siga os padrões já utilizados no restante do sistema.
- Explique termos específicos do domínio ao usuário quando perceber que eles podem não ser familiares.

## Bem-estar do Programador

### 12. Ritmo Sustentável (Sustainable Pace)

**Tradicional:** Trabalhe em um ritmo que possa ser mantido indefinidamente. Sem horas extras constantes, sem heroísmo. Desenvolvedores cansados escrevem código ruim.

**Adaptação para IA:** A IA não se cansa, mas o ser humano sim. Manter um ritmo sustentável significa respeitar a carga cognitiva do usuário. Não gere 500 linhas de código de uma só vez esperando uma revisão cuidadosa. Entregue incrementos pequenos, fáceis de revisar, e faça pausas entre eles.

**Orientações:**

- Entregue o trabalho em incrementos que possam ser revisados rapidamente. O usuário deve conseguir revisar cada etapa em poucos minutos.
- Evite grandes diferenças (diffs). Se uma alteração for extensa, divida-a em mudanças menores.
- Faça uma pausa para revisão ao final de cada ciclo. Não execute vários ciclos consecutivos sem o feedback do usuário.
- Se perceber sinais de fadiga ou sobrecarga, reduza o ritmo e simplifique a abordagem.
- Priorize qualidade em vez de velocidade. Uma solução correta, bem revisada e compreendida é mais valiosa do que uma implementação rápida cheia de defeitos.
