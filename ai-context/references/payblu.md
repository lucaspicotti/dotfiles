# AGENTS.md PayBlu

> Guia de contribuição técnica para agentes de IA (e humanos) específico deste repositório.

---

## 📌 Visão Geral do Projeto

O PayBlu é um sistema de telemetria e controle de transações financeiras para terminais de venda. O portal administrativo, as APIs REST e as rotinas de cron formam um monólito legado em evolução, com código Zend Framework 1.x convivendo com módulos modernos carregados por PSR-4.

* **Linguagem & Framework:** PHP 7.4, Zend Framework 1.x, Smarty para templates, JavaScript/jQuery legado e Sass para os estilos.
* **Banco de Dados:** PostgreSQL via `PDO_PGSQL`; a aplicação trabalha com o banco central e bancos de operador, além de integrações documentadas com ERP, VendTef e MicroMarket.
* **Estado/Escopo do Projeto:** Monólito de telemetria e transações financeiras, com portal administrativo, APIs versionadas, processamento por cron e uma camada moderna `App\` em `src/`.
* **Dependências Relevantes:** Guzzle 7 para HTTP, AWS SDK for PHP, phpseclib e OpenSpout. O Zend Framework 1 é uma biblioteca compartilhada externa ao repositório, normalmente disponível em `/var/www/Zend-VendTef`.
* **Integrações de Pagamento:** `App\Service\PaymentGateway\PaymentGateway` encapsula as chamadas HTTP do gateway usadas por `Api_AppV2_GatewayController`; o código e os mocks usam nomenclaturas Pagar.me/MundiPagg. ⚠️ A confirmar qual é o nome comercial e a versão da API atualmente suportada em produção.

---

## 🛠️ Comandos do Projeto

Execute os comandos a partir da raiz do PayBlu. Docker com o plugin Compose e a biblioteca Zend compartilhada são pré-requisitos para a esteira completa.

```bash
# Setup inicial do ambiente de testes
composer test:setup

# Executar servidor de desenvolvimento local
# Não configurado no projeto

# Executar a suíte de testes principal
composer test

# Executar testes secundários (suítes isoladas)
composer test:unit
composer test:integration
composer test:functional
composer test:coverage
composer test:coverage:check

# Executar formatação e linters do código
./vendor/bin/phpcs

# Compilar ou observar os assets Sass
npm run build
npm run watch

# Executar a esteira completa em Docker
composer ci:check

# Executar ferramentas de análise de segurança / vulnerabilidades
# Não configurado no projeto
```

`composer ci:baseline:update` só deve ser usado quando o aumento intencional de cobertura justificar a atualização do baseline. As variáveis da infraestrutura de teste são `PAYBLU_ZEND_LIBRARY_PATH`, `PAYBLU_TEST_PROJECT`, `PAYBLU_TEST_DB_MODE`, `PAYBLU_TEST_DB_HOST`, `PAYBLU_TEST_DB_PORT`, `PAYBLU_TEST_DB_USER`, `PAYBLU_TEST_DB_PASSWORD`, `PAYBLU_TEST_UID`, `PAYBLU_TEST_GID` e `PAYBLU_MIN_COVERAGE`. Não há `.env.example` no repositório. Não foi encontrado workflow de um provedor de CI; ⚠️ A confirmar onde `composer ci:check` é executado na integração contínua oficial.

---

## 🏗️ Estrutura e Arquitetura

### Backend

* **Aplicação Zend (`application/`)**: Contém o monólito legado. Controllers do portal ficam em `application/controllers/`, models normalmente estendem `Zend_Db_Table`, services orquestram regras de negócio, repositories concentram consultas/validações e templates ficam em `application/views/scripts/`.
* **APIs REST (`application/Api/`)**: Organizadas por contrato e versão em `V1`, `AppV2`, `Vendpago` e `VendpagoAdm`. Controllers seguem nomes como `Api_AppV2_GatewayController` e herdam as bases REST/criptográficas da própria versão.
* **Código PSR-4 (`src/`)**: Classes novas usam o namespace raiz `App\`, conforme o autoload do Composer. DTOs, respostas HTTP, paginação e serviços modernos ficam aqui.
* **Bibliotecas Legadas (`library/`)**: Reúne infraestrutura compartilhada, helpers, integrações e dependências incorporadas. Não edite cópias vendorizadas como `Zend`, `Smarty`, `MPDF6`, `PHPExcel` ou o conteúdo de `vendor/`.
* **Persistência (`application/models/` e `application/repository/`)**: Prefira `Zend_Db_Select`, parâmetros vinculados e repositories para consultas complexas. Preserve a distinção entre banco central e banco do operador e use transações nas operações financeiras que precisam ser atômicas.
* **Processamento Assíncrono (`application/cron/`, `cli.php`)**: Abriga rotinas de e-mail, faturamento, relatórios e controle dos terminais executadas fora do fluxo HTTP.
* **Integrações Externas:** `src/Service/PaymentGateway/` isola o gateway de pagamento com Guzzle; `application/services/Storage/S3Storage.php` encapsula S3; `application/services/Relatorios/ErpRelatoriosClient.php` encapsula o envio de relatórios ao ERP. Configurações e credenciais vêm da configuração Zend/`Zend_Registry`, nunca devem ser fixadas em código novo, logs ou fixtures.
* **Padrões Críticos:**
  * Preserve a retrocompatibilidade dos contratos em `application/Api/`, especialmente `AppV2`; alterações de payload, status HTTP, autenticação ou criptografia exigem testes de contrato/regressão.
  * Controllers do portal devem herdar a base adequada (`Henger_Controller_Action`); APIs devem herdar a base REST correspondente à sua versão.
  * Valide permissões com `checkPerm()`, proteja operações mutáveis do portal com CSRF e mantenha erros internos fora das respostas públicas.
  * Mantenha chamadas HTTP de adquirentes/gateways nos clients/services existentes, sem espalhá-las por controllers ou models.
  * Valores monetários persistidos como centavos devem continuar em centavos entre banco, DTO e resposta, salvo conversão explícita na borda de apresentação.

### Frontend

* **Templates (`application/views/scripts/`)**: O portal usa Smarty em arquivos `.tpl`, organizados por controller/tela; partials específicos ficam em subpastas `partial/` quando a tela os possui.
* **JavaScript (`public/scripts/`)**: Scripts são JavaScript tradicional e jQuery, em geral agrupados por funcionalidade ou tela. Não há framework SPA nem suíte JavaScript configurada.
* **Estilização/CSS:** O fonte Sass fica em `frontend/scss/`; `entries/` define os pontos de entrada, `abstracts/tokens/` concentra tokens, `components/` reúne componentes reutilizáveis e `layout/` contém estruturas de página. A compilação gera CSS em `public/styles/modern/`.
* **Padrões Críticos:**
  * Reutilize tokens de cor, tipografia, espaçamento e raio antes de introduzir valores locais.
  * Importe componentes compartilhados com `@use` nos arquivos de `entries/` e mantenha estilos específicos sob uma classe raiz da página para evitar vazamento para telas legadas.
  * Mantenha templates, scripts e entry Sass alinhados à pasta/nome da funcionalidade existente.

---

## 🧪 Práticas de Teste

* **Frameworks Utilizados:** PHPUnit 9.6, com configurações separadas em `tests/phpunit-unit.xml`, `tests/phpunit-integration.xml` e `tests/phpunit-functional.xml`. Não há framework de teste JavaScript configurado.
* **Organização:** Arquivos e classes terminam em `Test`; métodos descrevem o comportamento esperado. Use Arrange/Act/Assert e mantenha em `setUp()` somente a preparação comum.
* **Suíte Unit (`tests/Unit/`):** Não deve acessar rede, banco ou filesystem real, exceto temporários. Use fakes nomeadas, como as de `tests/Support/ControllerUnitFakes.php`, e exponha seams protegidos no código legado quando necessário para substituir models/services.
* **Suíte Integration (`tests/Integration/`):** Estenda `IntegrationTestCase`. Ela conecta apenas aos dois PostgreSQL de teste permitidos pelo `Tests_DatabaseGuard` e, por padrão, envolve cada teste em transações revertidas no `tearDown()`.
* **Suíte Functional (`tests/Functional/`):** Estenda `FunctionalTestCase` para fazer dispatch real do Zend. Use `configurarPrivilegio()` para preparar ACL e deixe a classe base limpar o cache. As fixtures de usuário, nível, operador e permissão são sintéticas e isoladas.
* **Políticas de Mock/Stub:**
  * Substitua apenas fronteiras reais de I/O por fakes nomeadas; não faça chamadas reais a gateways, adquirentes, S3, ERP ou outros serviços em testes unitários.
  * Não use bancos de desenvolvimento, homologação ou produção. Dados necessários devem ser sintéticos e inseridos pelo próprio teste.
  * Se o código testado executar `commit()` explícito, defina `$wrapInTransaction = false` e implemente limpeza determinística no `tearDown()`, seguindo `PersistenciaEvadtsTest`.
* **Gateway de Pagamento:** Existem artefatos Mockoon e scripts manuais em `tests/mocks/mockoon/pagarme/`, mas não foi localizado teste PHPUnit dedicado a `App\Service\PaymentGateway\PaymentGateway`. ⚠️ A confirmar se esses cenários são executados fora da esteira versionada; novas mudanças no client devem ganhar testes automatizados com cliente HTTP falso e payloads totalmente sintéticos, sem dados de cartão ou credenciais.
* **Cobertura:** `composer test:coverage` gera os relatórios e `composer test:coverage:check` compara o Clover ao baseline. Não reduza o baseline para fazer a esteira passar.

---

## ✅ Do (O que fazer)

- [ ] Manter os commits atômicos e descritos na ordem do fluxo.
- [ ] Adicionar testes correspondentes para qualquer regra de negócio nova ou teste de regressão para bug corrigido.
- [ ] Manter compatibilidade com PHP 7.4 e com as convenções do Zend Framework 1.x nas áreas legadas.
- [ ] Usar classes `App\` sob `src/` para código moderno e atualizar o autoload apenas quando a estrutura realmente exigir.
- [ ] Usar `Zend_Db_Select`, placeholders e parâmetros vinculados para valores externos em SQL.
- [ ] Validar autenticação, autorização, CSRF e formato de entrada nos limites HTTP apropriados.
- [ ] Tratar venda, cancelamento, pré-autorização e atualização de saldo como fluxos financeiros críticos, com atomicidade e testes de falha.
- [ ] Encapsular APIs externas nos services/clients existentes e representar respostas do gateway por `App\Service\PaymentGateway\Response` quando essa for a integração alterada.
- [ ] Reutilizar tokens e componentes Sass de `frontend/scss/` e validar assets com `npm run build`.
- [ ] Executar `composer test` e `./vendor/bin/phpcs` antes de concluir mudanças PHP; para validação equivalente à esteira, executar `composer ci:check`.

---

## ❌ Don't (O que NÃO fazer)

- **Não** leia variáveis de ambiente diretamente no código de negócio; centralize configuração na infraestrutura Zend ou nos helpers de teste já existentes.
- **Não** inclua senhas, tokens, chaves de gateway/adquirente, dados de cartão ou credenciais em código, logs, respostas, fixtures ou documentação.
- **Não** faça interpolação de entrada externa em SQL; mesmo ao tocar código legado, use binding ou `Zend_Db_Select`.
- **Não** altere silenciosamente rotas, payloads, códigos HTTP, autenticação ou criptografia das APIs versionadas.
- **Não** chame gateways, S3 ou ERP diretamente de novos controllers/models quando existe ou cabe um client/service de fronteira.
- **Não** execute testes Integration/Functional contra bancos que não passem pelo guard e pelo Compose de teste.
- **Não** dependa de ordem de execução, dados deixados por outro teste ou cache de ACL antigo.
- **Não** adicione bibliotecas externas ou dependências novas sem justificar a real necessidade e a compatibilidade com PHP 7.4.
- **Não** edite `vendor/`, bibliotecas incorporadas de terceiros em `library/` ou CSS compilado quando a fonte correspondente estiver em `frontend/scss/`.
- **Não** altere arquivos ou configurações estruturais de CI/CD sem autorização explícita do usuário.
- **Não** realize refatorações amplas em arquivos legados fora do escopo da tarefa solicitada.

---

## 📋 Checklist de Pull Request

- [ ] A descrição explica motivação, impacto e instruções passo a passo para testar a mudança.
- [ ] `composer test` passa sem regressões; as suítes afetadas também foram executadas isoladamente durante o desenvolvimento.
- [ ] `./vendor/bin/phpcs` passa segundo PSR-12, limite recomendado de 120 caracteres e limite absoluto de 150.
- [ ] `npm run build` passa quando templates, JavaScript, Sass ou assets foram alterados.
- [ ] O gate de cobertura não regrediu; atualizações do baseline representam somente aumento intencional de cobertura.
- [ ] Não há vazamento de dados sensíveis, credenciais, dados de cartão ou informações reais de clientes/transações.
- [ ] Consultas SQL novas ou alteradas usam binding e preservam a seleção do banco correto.
- [ ] Fluxos financeiros preservam atomicidade, tratamento de falhas e idempotência quando aplicável.
- [ ] Contratos das APIs REST, permissões, CSRF, autenticação e criptografia permanecem compatíveis e cobertos por testes.
- [ ] O código segue o estilo de arquitetura e design descritos neste documento.
