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
