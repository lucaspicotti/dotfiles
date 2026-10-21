# Componentes

Este documento orienta a IA a localizar e reutilizar componentes visuais do ERP.

## Onde procurar

- Partials: `application/views/scripts/partial/`
- Estilos: `public/styles/modern/` e arquivos de entrada do SCSS do projeto
- Scripts: `public/scripts/`

## Regra de uso

- Prefira reaproveitar um componente existente.
- Se a tela exigir algo novo, verifique se o padrão pode virar componente reutilizável.
- Use `vendpago-*` nas classes quando o componente já seguir esse padrão.
- Nunca use CSS inline.

## Componentes comuns

- `vendpago-page-header`
- `vendpago-alertbanner`
- `vendpago-btn`
- `vendpago-card`
- `vendpago-empty-state`
- `vendpago-kebab`
- `vendpago-modal`
- `vendpago-screen-modal` (ver seção abaixo)
- `vendpago-dropzone`
- `vendpago-choice-cards`
- `vendpago-counter`
- `vendpago-switch`
- `vendpago-date-wrapper`
- `vendpago-currency-input`
- `vendpago-sort`
- `vendpago-pagination`
- `vendpago-data-table`
- `vendpago-checkbox`
- `vendpago-file-card`
- `vendpago-select` (ver seção abaixo)
- `vendpago-select-dropdown` (ver seção abaixo)

## Selects customizados

Existem dois componentes. Escolha pelo markup que a tela já tem:

- **`vendpago-select`** (`components/_select.scss` + `public/scripts/vendpago-select.js`, JS vanilla, sem jQuery): o padrão para formulários e filtros novos. Visual do design system Vendpago (Claude Design). Basta marcar o `<select>`, e o JS monta o trigger e o painel.
  - Markup: `<select id="..." data-vendpago-select>`. Opcionais: `data-vendpago-select-icon="storefront"` (ícone à esquerda) e `data-vendpago-select-busca="Buscar categoria"` (campo de busca no topo, para listas longas; ignora acento e caixa).
  - Inclua o script na view e `@use "../components/select";` no entry da página.
  - Prévia com todos os estados: `/sandbox/componentes` (card "Select estilizado").
  - Visual (protótipo Produtos Mobile do Claude Design): trigger de 40px, peso 500, borda `$color-surface-border`, hover `$color-outline-variant`, aberto com borda `$color-primary-container` + anel `$secondary-container` e seta girando 180°. Painel com borda e `$shadow-md`; lista com padding de 4px, 232px de altura máxima e barra de rolagem fina. Opções com 40px; a selecionada tem fundo `$secondary-container`, texto `$color-primary` em peso 600 e `check`.
  - Busca: cabeçalho integrado ao painel (44px, linha inferior, input sem borda) com botão de limpar quando há texto. Sem resultado mostra "Nenhum resultado para “termo”".
  - Uma primeira opção de value vazio ("Todas"/"Todos") fica separada das demais por um divisor e some durante a busca.
  - O `<select>` nativo continua sendo a fonte do valor. O JS dispara `change` nativo, que também chega a `jQuery.on('change')`.
  - Sincronizado sozinho (MutationObserver): `disabled`, erro (classe `.vendpago-input-error-style` da validação inline ou `aria-invalid="true"`) e a lista de `<option>`.
  - **Valor alterado por código não é detectado.** Depois de `select.value = x` ou `$(select).val(x)`, dispare `select.dispatchEvent(new Event('change', { bubbles: true }))` ou chame `VendpagoSelect.refresh(select)`. **`.trigger('change')` do jQuery não chega ao componente.**
  - Conteúdo inserido depois do carregamento (AJAX): `VendpagoSelect.init(containerEl)`. Com `VendpagoInfiniteScroll`, use a opção `onAppend`.
  - Sem `<label for>` (ex.: célula de tabela), passe `aria-label` no `<select>`: ele vira o nome do trigger.
  - Teclado: ↓/↑/Enter/Espaço abrem; ↓/↑/Home/End navegam; Enter/Espaço escolhem; Esc fecha só a lista (não fecha o modal/folha); Tab fecha. Com busca: ↓ vai do campo às opções, ↑ na primeira opção volta ao campo, digitar numa opção leva ao campo e Enter no campo escolhe a primeira opção filtrada. Em touch, o foco não vai para a busca, para o teclado virtual não subir sozinho.
  - A largura vem do container. A altura (40px) pode ser sobrescrita em `.vendpago-select__trigger` (ex.: 36px em tabela, 44px em mobile).
  - Se o container tiver `overflow` e cortar a lista (ex.: folha de filtros mobile), use `position: static` em `.vendpago-select__painel`.
  - Dentro de `.vendpago-data-table` a lista não é cortada nem fica atrás das linhas: `_data-table.scss` e `_table.scss` tratam com `:has(.vendpago-select.is-open)`.
  - O painel usa `$z-dropdown`. Se a página tiver barra `sticky` com z-index baixo, baixe o z-index do `.vendpago-select__painel` nesse contexto (ex.: cards de `/produtos`). Card com `transform` no hover (`.vendpago-card`) vira stacking context: suba o card com `:has(.vendpago-select.is-open)` (ex.: filtros de `/produtos`).
  - Referência: `/produtos` (categoria na listagem e filtros Tipo/Categoria/Fornecedor/Situação).
- **`vendpago-select-dropdown`** (`public/scripts/vendpago-select-dropdown.js`, carregado no `header.tpl`): variante montada sobre o `vendpago-dropdown` (mesmo visual do menu kebab), com markup manual (`data-dropdown data-select-dropdown` + trigger + `<ul data-dropdown-menu>` + select). Já é usado em gráficos, NPS e `partial/vendpago-pagination.tpl`. Mantenha-o nesses lugares.

## Modal de tela (`vendpago-screen-modal`)

Modal com cabeçalho de tela (breadcrumb, título e subtítulo) sobre `<dialog>` nativo, sem Bootstrap e sem jQuery. No desktop é um diálogo centralizado; no mobile (até `$breakpoint-mobile`, 899.98px) ocupa a tela inteira, com rodapé fixo, como uma tela nova. Use para formulários de criação/edição curtos que não justificam uma página. Para conteúdo injetado por JS (confirmações, avisos), continue no `vendpago-modal`.

- Arquivos: `partial/vendpago-screen-modal.tpl`, `components/_screen-modal.scss`, `public/scripts/vendpago-screen-modal.js`.
- Inclua o script na view e `@use "../components/screen-modal";` no entry.
- Prévia: `/sandbox/componentes` (card "Modal de tela").
- Parâmetros: `id`, `title`, `subtitle`, `breadcrumb` (só no mobile; itens viram texto e o penúltimo fecha o modal, como "voltar"), `size` (`sm` | `md` | `lg`), `closeOnBackdrop` (`false` em formulários longos), `bodyContent` e `footerContent` via `{capture}`.
- Rodapé: ação primária antes da secundária.
- Abrir/fechar: `data-vendpago-screen-modal-open="id"` no gatilho e `data-vendpago-screen-modal-close` dentro do modal (com `vendpago-btn.tpl`, use `dataAttrs=['vendpago-screen-modal-close' => '']`), ou `VendpagoScreenModal.open('id')` / `.close('id')`.
- Eventos no `<dialog>`: `vendpago-screen-modal:open` e `vendpago-screen-modal:close` (ex.: limpar o formulário).
- Comportamento: Esc fecha (com um `vendpago-select` aberto dentro, fecha só a lista); clique no fundo fecha; foca `[autofocus]` ou o primeiro campo do corpo e devolve o foco a quem abriu; trava a rolagem da página.
- Acessibilidade: título em `<h2>` (a página já tem `<h1>`), ligado por `aria-labelledby`; subtítulo em `aria-describedby`.
- Dentro do corpo do modal (que rola), a lista do `vendpago-select` abre no fluxo (`position: static`), empurrando os campos de baixo.
- **Camada superior:** o `<dialog>` aberto fica acima de tudo, sem z-index. Elementos anexados ao `<body>` (overlay de loading global, toasts, menu do kebab reposicionado) ficam **por trás** enquanto o modal está aberto. Dentro do modal, mostre carregamento no próprio botão/corpo e prefira componentes que renderizam no lugar, como o `vendpago-select`.

## Como implementar

1. Identifique a necessidade funcional.
2. Busque o partial correspondente.
3. Verifique o SCSS do componente.
4. Verifique o JS associado.
5. Se não existir, pergunte antes de criar.

## Decisão de criação

Crie um novo componente apenas quando:

- houver reutilização real;
- o comportamento se repetir em mais de uma tela;
- a implementação puder ficar isolada;
- o componente puder ser documentado para uso futuro.
