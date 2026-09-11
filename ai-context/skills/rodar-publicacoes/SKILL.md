---
name: rodar-publicacoes
description: Analisa um controller de publicações estilo Zend1/Henger (métodos publicacao*Action que rodam querysTef/querysOpDefault/addSubMenu), compara os artefatos de cada publicação (tabelas, colunas, índices, módulos, privilégios, submenus, linhas de lookup) com o banco de dados local do projeto atual, lista quais publicações ainda não rodaram (considerando dependências entre elas), e — mediante confirmação do usuário — roda as pendentes via um runner PHP que chama a action diretamente, sem passar pela tela web/login. Use quando o usuário pedir para verificar publicações pendentes, sincronizar o banco local com as publicações do sistema, ou "rodar o PublicacaoController". Funciona em qualquer projeto que siga esse padrão (não específico de um único projeto). NÃO use para migrations de framework padrão (Laravel, Doctrine, Rails, Django, Prisma) — é específico desse padrão legado de "publicação" via controller.
---

# Rodar Publicações

Use esta skill para descobrir quais métodos `publicacao*Action` de um controller de publicações (padrão Zend1/Henger: `querysTef`, `querysOpDefault`, `querysOp`, `addSubMenu`) ainda não foram aplicados no banco de dados local do projeto atual, e — se o usuário quiser — rodá-los diretamente, sem precisar logar no sistema pela tela web.

O objetivo não é só listar métodos. É determinar, com evidência real do banco, o que já rodou e o que falta, respeitando dependências entre publicações que a ordem do arquivo/numeração nem sempre reflete.

## Regras de Segurança

- **Nunca rodar contra um host que não seja comprovadamente local/dev.** O arquivo de config commitado no repositório pode apontar para um host remoto (ex.: um IP interno de produção/homologação) enquanto o ambiente local usa um override fora do repo. Antes de conectar, procure ativamente por esse override (`/etc/<app>/*.ini`, `.env`, variável de ambiente, config local ignorado pelo git) e confirme qual config está realmente ativo. Se houver dúvida, leia o Bootstrap da aplicação (ex.: `_initApplicationConfig`/equivalente) em vez de assumir o config do repo.
- **Nunca rode `querysOpDefault`/loops multi-tenant sem filtrar antes para bancos que existem localmente.** Sem esse filtro, o runner pode tentar conectar em centenas de bancos de operadores/clientes de produção e travar ou falhar no meio do loop. Descubra os bancos locais existentes (ex. `SELECT datname FROM pg_database WHERE datname LIKE 'op\_%'` ou padrão equivalente do projeto) e filtre a lista de "operadores"/"tenants" antes de rodar qualquer loop multi-banco.
- **Nunca suponha que uma query é idempotente.** Leia a query real (procure por `IF NOT EXISTS`, `WHERE NOT EXISTS`, `ON CONFLICT`) antes de assumir que é seguro reexecutar.
- **Sempre peça confirmação explícita do usuário antes de executar qualquer publicação.** Nunca rode automaticamente só porque encontrou pendências — apresente a lista e pergunte.
- **Depois de cada execução, reverifique no banco** os artefatos daquela publicação específica. Não confie apenas na ausência de exceção — uma query pode "passar" sem fazer o que deveria (ex. um `WHERE NOT EXISTS` que nunca bate).
- Se a action falhar por dependência de algo que só existe depois de outra publicação, **não pule a etapa com gambiarra** (ex. comentar a query problemática) — ajuste a ordem de execução ou rode primeiro o pré-requisito real.

## Fluxo de Trabalho

### Passo 1 — Localizar o controller de publicações

Procure, a partir da raiz do projeto atual, por um arquivo cujo nome combine com `*Publicacao*Controller.php` (ou nome equivalente, caso o projeto use outro termo para o mesmo padrão — ex. `Migracao`, `Release`, `Deploy`). Se houver mais de um candidato plausível, ou nenhum, pergunte ao usuário qual arquivo é.

### Passo 2 — Extrair os métodos de publicação

Rode algo como `grep -n "function publicacao.*Action" <arquivo>` (adapte o padrão do nome se o projeto usar outra convenção) para listar todos os métodos candidatos, com suas linhas. Leia o arquivo método a método — preferencialmente do mais recente (fim do arquivo) para o mais antigo, já que normalmente é o que está mais perto de rodar e mais relevante para o usuário no momento.

Preste atenção também a métodos **fora** do padrão de nome mas que sejam pré-requisitos de algum `publicacao*Action` (ex.: uma action antiga e isolada que cria uma tabela que uma publicação posterior assume que já existe). Eles precisam entrar na análise de dependências do Passo 3, mesmo não aparecendo na lista principal.

### Passo 3 — Mapear artefatos verificáveis por método

Para cada método, leia o corpo completo — dentro de `querysTef`, `querysOpDefault`, `querysOp`, `addSubMenu` e qualquer helper equivalente que exista no projeto — e monte uma lista de artefatos observáveis e verificáveis via SQL:

- `CREATE TABLE <nome>`
- `ALTER TABLE <tabela> ADD COLUMN <coluna>`
- `CREATE [UNIQUE] INDEX <nome>`
- `ADD CONSTRAINT <nome>`
- `INSERT INTO modulo (...) controller = '<X>'`
- `INSERT INTO privilegio (...) autorizacao = '<x>'`
- inserts fixos de linhas de lookup (ex. `boleto_status`, `terminal_status`) com valores/IDs específicos
- `addSubMenu([...'link' => ...])` — o `link` é o identificador mais estável para checar depois

Ao ler cada query, anote explicitamente quando ela referencia uma coluna/tabela/índice que só existe se **outro** método já rodou antes. Isso é a base para a ordem de execução segura do Passo 6 — a numeração/nome do método (ex. `publicacao300` vs `publicacao304`) não garante a ordem cronológica real de dependência.

### Passo 4 — Descobrir a config de banco real do projeto

Encontre o arquivo de config do framework usado pelo projeto (ex. `application/config.ini` em apps Zend1) e procure ativamente por overrides externos ao repositório (`/etc/<app>/*.ini`, `.env`, variável de ambiente). Teste a conexão com o cliente apropriado ao adapter (`psql` para Postgres, `mysql` para MySQL, etc.) **antes** de seguir para a verificação. Não assuma — valide de fato qual host/porta/banco está em uso.

### Passo 5 — Verificar cada artefato no banco

Para cada artefato mapeado no Passo 3, gere e rode consultas de existência:
- Tabelas: `information_schema.tables`
- Colunas: `information_schema.columns`
- Índices/constraints: `pg_indexes`/`pg_constraint` (Postgres) ou equivalente do adapter em uso
- Linhas de lookup: `SELECT` direto pela chave/valor esperado
- Submenus: `SELECT` na tabela de menu pelo `link`

Monte uma tabela de status por método:

| Método | Linha | Status |
|---|---|---|
| `publicacaoXXX` | N | ✅ Rodada / ❌ Não rodada / ⚠️ Parcial (detalhar o que falta) |

### Passo 6 — Determinar a ordem segura de execução

Use as dependências anotadas no Passo 3 para propor a ordem correta de execução das publicações pendentes. Essa ordem pode divergir da ordem por nome/numeração do método, e pode exigir rodar antes um pré-requisito fora do padrão `publicacao*` identificado no Passo 2.

### Passo 7 — Apresentar ao usuário e perguntar

Mostre a tabela de status, a ordem sugerida e qualquer dependência/pré-requisito detectado. Pergunte explicitamente se o usuário quer rodar as publicações pendentes agora — deixe claro que ele pode escolher rodar todas ou só um subconjunto.

### Passo 8 — Rodar (somente se confirmado)

1. Copie `runner.template.php` (nesta mesma pasta da skill) para o scratchpad da sessão atual.
2. Preencha os placeholders do template para o projeto atual (raiz do projeto, arquivo/classe do controller, forma de bootstrap do framework — veja comentários no template).
3. Execute as actions pendentes uma a uma, na ordem definida no Passo 6, parando e reportando no primeiro erro (não continue "pulando" erros silenciosamente).
4. Depois de cada execução bem-sucedida, repita a verificação do Passo 5 só para aquele método, para confirmar que os artefatos esperados agora existem de fato.

### Passo 9 — Resumo final

Reporte objetivamente: o que rodou com sucesso, o que falhou (e por quê, se falhou), e o estado final de cada publicação da lista original.

## Critérios de Conclusão

Esta skill foi bem executada quando:

- o controller de publicações foi localizado corretamente (ou o usuário foi consultado quando ambíguo/ausente);
- todos os métodos de publicação foram lidos e tiveram seus artefatos mapeados;
- a config de banco **realmente ativa** (não necessariamente a do repositório) foi usada para verificação;
- cada artefato foi confirmado com evidência de banco, nunca por suposição;
- dependências entre publicações foram checadas antes de sugerir qualquer ordem de execução;
- o usuário deu aceite explícito antes de qualquer execução;
- cada execução foi confirmada por reverificação pós-execução, não apenas pela ausência de exceção.
