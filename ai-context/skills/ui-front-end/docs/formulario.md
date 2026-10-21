# Formulário

Este documento orienta a IA a localizar e montar formulários do ERP com os componentes corretos.

## Onde procurar

- Partials: `application/views/scripts/partial/`
- Formulários renderizados: telas com `Zend_Form`
- Scripts: `public/scripts/vendpago-form-utils.js`, `public/scripts/vendpago-toggle-switch.js`, `public/scripts/vendpago-currency-input.js`
- Estilos: `public/styles/modern/`

## Regras

- Prefira reutilizar wrappers e componentes já existentes.
- Use classes `vendpago-*` quando o formulário seguir o design system.
- Nunca use CSS inline.
- Prefira JavaScript vanilla quando for criar comportamento novo.
- Se a tela depender de um novo tipo de campo recorrente, avalie criar componente reutilizável.

## Estrutura esperada

- `page-header`
- card ou shell de formulário
- campos organizados por grupo
- validação visual
- ação principal e ação secundária

## Formulário em tela de modal no mobile (`vendpago-screen-form`)

Para telas de formulário (`.tpl` próprio, `Zend_Form`) que no mobile devem parecer o `vendpago-screen-modal` em tela cheia, sem abrir modal nem mudar o backend. No desktop nada muda.

- Arquivos: `components/_screen-form.scss` (`@use` no entry) e `public/scripts/vendpago-screen-form.js`.
- Marcação no container da página: classe `vendpago-screen-form` + `data-screen-form="<seletor do form>"`, e no fim do container `<footer class="vendpago-screen-form__rodape" data-screen-form-rodape></footer>`.
- O "Voltar" do cabeçalho recebe `vendpago-screen-form__voltar` (no `vendpago-page-header.tpl`: `'extraClass' => "vendpago-screen-form__voltar"` no `actionButton`) e vira o "←" à esquerda.
- No mobile: esconde navbar, menu lateral e barra inferior; cabeçalho fixo (←, breadcrumb, título); card sem moldura; botões do form (`.btn-forms-bootstrap`) movidos para o rodapé fixo, com área segura. A `action-bar` fica só no desktop.
- Use só em telas cujo "Voltar" leve a um destino fixo e válido (todas as entradas vêm de dentro do app), porque o cromo do app some.
- Em uso: `/produtos/add`, `/produtos/edit/pid/X`, `/produtos/duplicate/pid/X`, `/produtos/ativar/pid/X`, `/produtos/inativar/pid/X`, `/erp/add-produto-xml`.

## Casos comuns

- `vendpago-date-wrapper`
- `vendpago-switch`
- `vendpago-counter`
- `vendpago-currency-input`
- `select2` / `select-com-filtro` quando já adotado pela tela

## Quando parar e perguntar

- se o campo novo não tiver padrão equivalente;
- se o comportamento exigir alteração estrutural no formulário;
- se houver risco de duplicar solução já existente.
