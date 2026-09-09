---
name: api-doc-generator
description: "Use this skill to generate Markdown API endpoint documentation from a .http test/reference file plus the source files implementing the feature (controller, service, DTOs, validators, routes). Triggers include: user provides or references a .http file and asks to document/generate documentation for its endpoints, mentions 'documentação de endpoints', 'gerar documentação da API', or asks to document a controller. Always produces the final file under /var/www/docs/api using the api_doc_template.md skeleton in this skill's directory. Do NOT use for OpenAPI/Swagger spec generation, Postman collections, or documentation unrelated to HTTP endpoints."
---

# Gerador de documentação de endpoints de API

Gera documentação Markdown de endpoints a partir de duas fontes de entrada fornecidas pelo usuário:

1. **Arquivo `.http`** de teste/exemplo — é a base para os exemplos de requisição, métodos, rotas, parâmetros e bodies reais.
2. **Arquivos da funcionalidade** (controller, service, validators, DTOs, rotas, etc.) — usados para entender as regras de negócio, validações, condições de erro e derivações de campos que o `.http` sozinho não explica.

O resultado final é sempre um arquivo Markdown salvo em `/var/www/docs/api/`, seguindo o esqueleto de `template.md` (neste mesmo diretório da skill).

## Fluxo de trabalho

### 1. Reunir as entradas
- Se o usuário não indicou o caminho do `.http` ou dos arquivos da funcionalidade, pergunte por eles antes de prosseguir — não invente endpoints.
- Leia o `.http` na íntegra: cada bloco separado por `###` (ou por linha em branco, dependendo do formato) é um endpoint/cenário candidato.
- Leia os arquivos da funcionalidade indicados para extrair:
  - Prefixo de rota e nome do controller.
  - Regras de negócio, validações e ordem dos passos de cada ação.
  - Condições que geram cada código de erro (400, 404, 409, 500, etc.) e a mensagem retornada.
  - Regras de derivação/mapeamento de campos (campos calculados, campos que não vêm prontos no payload).
  - Se algum parâmetro/header além de `Authorization` é usado para autenticação/autorização.

### 2. Mapear `.http` → endpoints
- Cada requisição distinta no `.http` (combinação de método + path) vira uma seção `## N. Título` no documento final, numerada na ordem em que aparecem no arquivo.
- Se o `.http` tiver múltiplos cenários para o mesmo endpoint (ex.: com e sem parâmetro opcional, payload mínimo vs. completo), use-os como "Exemplo de {{cenário}}" dentro da mesma seção do endpoint, não como endpoints separados.
- Não invente endpoints que não estejam no `.http`. Se o código-fonte mostrar uma rota que não tem exemplo no `.http`, avise o usuário e pergunte se deseja documentá-la mesmo assim.

### 3. Preencher o esqueleto (`api_doc_template.md`)
Abra `api_doc_template.md` neste diretório e use-o como esqueleto. Regras de preenchimento:

- **Remova todos os comentários HTML** (`<!-- ... -->`) do resultado final — eles são apenas instruções para você, não fazem parte da documentação.
- **"Regras gerais do fluxo" é opcional.** Inclua somente se houver regras que se apliquem a mais de um endpoint (ex.: mapeamento de campo compartilhado, efeito colateral assíncrono comum). A quantidade de itens é livre; se não houver nenhuma regra transversal, remova a seção inteira.
- **"🔒 Autenticação" é sempre obrigatória** e deve seguir exatamente o padrão fixo do template (mesmo texto, mesma tabela, mesma resposta 401), a menos que o código mostre explicitamente um mecanismo de autenticação diferente — nesse caso, adapte o conteúdo mas mantenha a seção.
- **Uma seção por endpoint, na quantidade real encontrada no `.http`** — nunca um número fixo de endpoints.
- Dentro de cada endpoint:
  - **"Comportamento"** e subseções de regras específicas (derivação de campo, regras de um campo) são **opcionais**: inclua apenas quando houver lógica relevante para o consumidor da API entender, e com a quantidade de passos que a funcionalidade exigir.
  - **"Parâmetros"** é **obrigatório**. Se não houver parâmetros de query/path/header, escreva explicitamente que o endpoint não recebe parâmetros — não deixe uma tabela vazia.
  - **"Body"** é opcional — inclua apenas para métodos que recebem corpo de requisição.
  - **"Exemplo de requisição"** é **obrigatório** e deve ser extraído do `.http` real (método, path, headers, query string, body), não inventado. Se houver mais de um cenário relevante, repita o bloco com título "Exemplo de {{cenário}}".
  - **"Respostas"** é **obrigatório**: pelo menos uma resposta de sucesso. A quantidade e os códigos de erro (`400`, `404`, `409`, `500`, etc.) variam conforme o que o código-fonte realmente trata — não crie cenários de erro que não existem no código.

### 4. Nomear e salvar o arquivo
- Nome sugerido: `{{nome-do-controller-em-kebab-case}}.md` (ex.: `pedidos-controller.md`). Se o usuário já indicou um nome de arquivo, use-o.
- Garanta que o diretório existe e salve o arquivo final ali:
  ```bash
  mkdir -p /var/www/docs/api
  ```
- Escreva o Markdown final (sem os comentários de instrução do template) diretamente em `/var/www/docs/api/{{nome-do-arquivo}}.md`.

### 5. Apresentar o resultado
- Após salvar, disponibilize o arquivo para o usuário com a ferramenta de apresentação de arquivos.
- Se alguma informação necessária (regra de negócio, condição de erro, etc.) não puder ser confirmada nem pelo `.http` nem pelos arquivos da funcionalidade, sinalize isso ao usuário em vez de preencher com suposições — deixe um placeholder claro ou pergunte diretamente.

## Referências
- `template.md` — esqueleto completo com todas as seções, marcações de obrigatório/opcional e instruções de repetição.
