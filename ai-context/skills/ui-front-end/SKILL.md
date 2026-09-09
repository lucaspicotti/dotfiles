---
name: ui-front-end
description: Skill para orientar IA na criação e evolução de interfaces do ERP Vendpago/Telemetria-ERP. Use quando a tarefa envolver telas novas, componentes visuais, tabela, formulário, SCSS do design system ou decisões de reaproveitamento de partials e scripts.
---

# UI Front-End

Use esta skill antes de implementar qualquer tela nova ou ajustar interface existente.

## Objetivo

Garantir que a IA localize o padrão correto, reutilize o que já existe e siga a estrutura visual do sistema sem criar CSS inline, sem hardcode de design e sem duplicar componentes.

## Regras Centrais

- Use sempre classes com prefixo `vendpago-*` quando o padrão do sistema já existir.
- Nunca use CSS inline.
- No SCSS, use sempre as variáveis do design system.
- Prefira JavaScript vanilla. Use jQuery apenas quando o projeto já depender disso ou quando o padrão existente exigir.
- Antes de criar algo novo, procure componente, partial, estilo e script já existentes.
- Se não houver componente adequado, avalie criar um novo componente reutilizável em `partial/*.tpl`, `components/*.scss` e, se necessário, `public/scripts/*.js`.
- Se faltar contexto, pergunte antes de implementar.
- Antes de implementar, escreva um plano de ação curto e peça aprovação.

## Estrutura Base de Tela

Toda página nova deve começar com esta ordem:

```text
Header
├── Breadcrumb
├── Título
├── Subtítulo (opcional)
└── Botão de ação principal (opcional)
```

Depois disso, a tela deve seguir com uma destas estruturas:

- `card`
- `tabela`
- `formulário`
- outro bloco de conteúdo validado pelo contexto da tela

## Como Decidir

1. Identifique o tipo de tela.
2. Consulte a documentação de apoio em `./docs/`.
3. Reutilize o que já existe.
4. Se o padrão não existir, pergunte se deve ser criado.
5. Se for criar, mantenha a solução pequena, modular e reutilizável.

## Padrão de SCSS

O projeto usa uma organização modular de Sass:

```text
abstracts/
base/
layout/
components/
entries/
```

Regras:

- `abstracts/` concentra `variables` e `mixins`.
- `base/` contém reset e regras globais.
- `layout/` define a estrutura geral da aplicação.
- `components/` contém componentes isolados, com responsabilidade única.
- `entries/` é o único lugar que compila o CSS final.
- Ao criar componente novo, crie um partial iniciando com underline, por exemplo `_my-component.scss`.
- Importe o componente no entry correspondente.
- Não crie hardcode de cores, espaçamentos ou tipografia dentro do componente.

## Padrão de Implementação

- Tela nova com funcionalidades específicas: primeiro busque componentes existentes.
- Se o recurso não existir, avalie se vale criar um componente novo.
- Se o componente novo fizer sentido, crie também a documentação de uso para reutilização futura.
- O foco é consistência, não novidade visual.

## Leituras de Apoio

- [Componentes](./docs/componentes.md)
- [Tabela](./docs/tabela.md)
- [Formulário](./docs/formulario.md)

## Checklist Antes de Implementar

- A tela já existe em outro lugar?
- Existe partial pronto para este padrão?
- Existe classe `vendpago-*` equivalente?
- Existe SCSS do design system para isso?
- Existe JS reutilizável para o comportamento?
- A solução precisa ser um componente novo?
- O usuário já aprovou o plano de ação?

Se qualquer resposta estiver incerta, pergunte antes de codar.
