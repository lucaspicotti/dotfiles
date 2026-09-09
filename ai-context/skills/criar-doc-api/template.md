<!--
  TEMPLATE DE DOCUMENTAÇÃO DE API
  ================================
  Este arquivo é um ESQUELETO a ser preenchido pela skill "api-doc-generator".
  Os comentários HTML (como este) são instruções de preenchimento e NÃO devem
  aparecer no documento final gerado — devem ser removidos.

  Convenções:
  - {{VARIAVEL}}          -> valor a ser substituído.
  - Blocos marcados com "OPCIONAL" só entram no resultado final se fizerem
    sentido para a funcionalidade documentada. Se não se aplicar, remover
    o bloco inteiro (título incluso).
  - Blocos marcados com "REPETIR" indicam que a seção se repete uma vez por
    item (endpoint, parâmetro, resposta de erro, etc.), na quantidade que
    for necessária — nunca uma quantidade fixa.
-->

# API {{NOME_DA_API}} - {{PREFIXO_BASE_DA_ROTA}}

Esta documentação descreve os endpoints do controlador {{NOME_CONTROLLER}}, responsável por {{DESCRICAO_FUNCIONALIDADE}}.

<!--
  OPCIONAL — "Regras gerais do fluxo"
  Incluir esta seção somente se existirem regras de negócio que se aplicam
  a MAIS DE UM endpoint (ex.: mapeamento de campos, efeitos colaterais
  assíncronos, convenções compartilhadas). Se todas as regras forem
  específicas de um único endpoint, documente-as na seção do próprio
  endpoint e remova este bloco.
  A quantidade de itens da lista é livre (0 a N), conforme a necessidade.
-->
## Regras gerais do fluxo
1. {{Regra geral de negócio 1}}
2. {{Regra geral de negócio 2}}
<!-- ... adicionar/remover itens conforme necessário ... -->

## 🔒 Autenticação

Todas as chamadas exigem o cabeçalho HTTP `Authorization` com a chave correspondente à aplicação autorizada.

| Header | Tipo | Descrição | Valor Padrão (Exemplo) |
| :--- | :--- | :--- | :--- |
| `Authorization` | String | Token de autenticação/App Key | `1e11b1ed-c111-1b11-bbf1-111be111a111` |

### Resposta de Erro de Autenticação (401)

Caso a chave não seja enviada ou seja inválida:
```json
{
  "status": "erro",
  "mensagem": "App Key inválido ou não informado"
}
```

<!--
  A partir daqui, REPETIR uma seção "## N. {{Título}}" para cada endpoint
  encontrado no arquivo .http de referência, na ordem em que aparecem
  (ou na ordem lógica do fluxo, se fizer mais sentido). A numeração
  acompanha a quantidade real de endpoints — não é fixa em 3.
-->

## {{N}}. {{Título da ação do endpoint}}

`{{METODO}} {{PREFIXO_BASE_DA_ROTA}}{{/caminho-do-endpoint}}`

{{Descrição curta do que o endpoint faz.}}

<!--
  OPCIONAL — "Comportamento"
  Incluir apenas se houver lógica de negócio relevante para o consumidor
  da API entender (validações, buscas, condições). A quantidade de passos
  é livre, conforme a necessidade da funcionalidade.
-->
### Comportamento
1. {{Passo 1 da lógica de negócio}}
2. {{Passo 2 da lógica de negócio}}
<!-- ... adicionar/remover passos conforme necessário ... -->

<!--
  OPCIONAL — Subseções de regras específicas do endpoint (ex.: derivação
  de campos calculados, classificação de valores, regras sobre um campo
  específico). Criar quantas forem necessárias, com título descritivo do
  que está sendo explicado. Exemplo de títulos comuns:
  "### Derivação do campo {{campo}}", "### Regras do campo {{campo}}".
-->
### {{Título da regra específica, se houver}}
{{Explicação da regra.}}
1. {{Regra 1}}
2. {{Regra 2}}

<!--
  OBRIGATÓRIO — Parâmetros
  Sempre presente. Se o endpoint não receber nenhum parâmetro de
  query/path/header (fora a Authorization, já coberta na seção de
  autenticação), indicar explicitamente "Este endpoint não recebe
  parâmetros." em vez de deixar uma tabela vazia.
-->
### Parâmetros
| Nome | Local | Obrigatório | Tipo | Descrição |
|---|---|---|---|---|
| `{{parametro}}` | {{query/path/header}} | {{Sim/Não}} | {{tipo}} | {{descrição}} |
<!-- REPETIR uma linha por parâmetro -->

<!--
  OPCIONAL — Body
  Incluir apenas para endpoints que recebem corpo de requisição
  (POST/PUT/PATCH). Remover para GET/DELETE sem body.
-->
### Body
| Campo | Obrigatório | Tipo | Descrição |
|---|---|---|---|
| `{{campo}}` | {{Sim/Não}} | {{tipo}} | {{descrição}} |
<!-- REPETIR uma linha por campo -->

<!--
  OBRIGATÓRIO — Exemplo de requisição
  Sempre presente. Usar o exemplo real do arquivo .http de referência
  sempre que possível (método, path, headers, query string, body).
  Se houver mais de um cenário relevante (ex.: com/sem parâmetro
  opcional), REPETIR o bloco com um título "### Exemplo de {{cenário}}"
  para cada cenário.
-->
### Exemplo de requisição
```http
{{METODO}} {{PREFIXO_BASE_DA_ROTA}}{{/caminho-do-endpoint}}{{?query}} HTTP/1.1
Authorization: {{token}}
Content-Type: application/json
Accept: application/json

{{corpo da requisição, se houver}}
```

<!--
  OBRIGATÓRIO — Respostas
  Sempre presente pelo menos uma resposta de sucesso. A quantidade e os
  códigos de status (200, 201, 204, 400, 404, 409, 500, etc.) variam
  conforme a funcionalidade real — usar apenas os que existirem de fato
  no código/arquivo .http, sem inventar cenários.
-->
### Resposta `{{200/201/204}}`
```json
{
  "{{campo}}": "{{valor}}"
}
```

### Respostas de erro
<!-- REPETIR um bloco por código de erro identificado -->
`{{codigo}}` quando {{condição de erro}}:
```json
{
  "error": "{{Mensagem de erro}}"
}
```

<!-- Fim do bloco de endpoint. Repetir "## N. {{Título}}" para o próximo endpoint. -->
