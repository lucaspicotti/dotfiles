# Tabela

Este documento orienta a IA a identificar o padrão de telas com listagem, filtro e ações.

## Onde procurar

- Partials de apoio: `application/views/scripts/partial/`
- Tabelas de listagem: `vendpago-data-table`, `vendpago-table`
- Scripts: `public/scripts/vendpago-pagination.js`, `public/scripts/vendpago-client-table.js`
- Estilos: `public/styles/modern/`

## Estrutura esperada

- `page-header`
- bloco único com `vendpago-data-table`
- `pc-table-filters`
- `vendpago-table-container`
- estado vazio
- `vendpago-pagination`

## Regras

- Reutilize o wrapper de tabela existente antes de montar uma tabela manual.
- Use classes do padrão `vendpago-*`.
- Não use CSS inline.
- Não crie lógica de filtro duplicada se já existir script reutilizável.
- A partir de 3 ações na tabela, use kebab para agrupar as ações.
- Use o alinhamento de acordo com o conteúdo da célula e do cabeçalho:
  - conteúdo numérico: centralizado;
  - texto: alinhado à esquerda;
  - botão: centralizado.
- A primeira coluna, quando eu nomea-la como identificadora, deve seguir o padrão do sandbox: texto principal com cor mais chamativa e um subtítulo menor abaixo.
- Registros longos devem exibir no máximo 45 caracteres; depois disso, use `...` e mostre o texto completo em `title` ou tooltip equivalente.
- Use a badge de status no mesmo padrão do sandbox, com `vendpago-status-badge` e seu modificador.
- Ordenação e busca devem usar o comportamento padrão da tabela, sem implementação paralela.
- Quando a tela usar listagem, filtros e paginação, prefira o bloco único `vendpago-data-table` com `pc-table-filters`, `vendpago-table-container` e `vendpago-pagination`.

## Quando criar algo novo

Crie um novo padrão de tabela apenas se a tela exigir algo que não exista no sistema e o uso se repetir.

## Sinais de uso correto

- busca e ordenação seguem o comportamento do sistema;
- ações ficam isoladas na coluna final;
- empty state aparece quando não houver dados;
- paginação é consistente com o restante da aplicação.
