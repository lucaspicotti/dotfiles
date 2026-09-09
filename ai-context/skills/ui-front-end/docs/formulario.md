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
