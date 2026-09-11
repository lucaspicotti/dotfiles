<?php
/**
 * TEMPLATE — não rode este arquivo direto da pasta da skill.
 *
 * Copie para o scratchpad da sessão atual e preencha os placeholders
 * {{...}} abaixo para o projeto específico antes de executar. Este script
 * faz bootstrap da aplicação e chama a(s) action(s) do controller de
 * publicações DIRETAMENTE (sem passar pelo dispatch HTTP), então qualquer
 * checagem de login/permissão que exista em preDispatch() é naturalmente
 * bypassada — isso é intencional (rodar localmente sem precisar logar),
 * mas só deve ser usado contra um banco comprovadamente local/dev
 * (ver Regras de Segurança no SKILL.md).
 *
 * Uso:
 *   php runner.php <action1> [action2 ...]
 * Ex.:
 *   php runner.php publicacao21072026 publicacao22062026
 */

if ($argc < 2) {
    fwrite(STDERR, "Uso: php runner.php <action1> [action2 ...]\n");
    exit(1);
}

// ---------------------------------------------------------------------
// 1) Ajuste estes caminhos para o projeto atual.
// ---------------------------------------------------------------------
$rootDir = '{{ROOT_DIR}}';          // ex.: '/var/www/Erp/'  (com barra no final)
$appPath = $rootDir . '{{APP_PATH_RELATIVE}}'; // ex.: 'application/'

chdir($rootDir);

define('ROOT_DIR', $rootDir);
define('APP_PATH', $appPath);
define('APPLICATION_ENV', 'development');

set_include_path('library'
    . PATH_SEPARATOR . './application/'
    . PATH_SEPARATOR . './application/models/'
    . PATH_SEPARATOR . './application/forms/'
    . PATH_SEPARATOR . get_include_path());

require $rootDir . 'vendor/autoload.php';

// ---------------------------------------------------------------------
// 2) Bootstrap do framework. Ajuste conforme o projeto — o bloco abaixo
//    assume Zend Framework 1 com Zend_Application (mesmo padrão do
//    index.php real do projeto), chamando SÓ bootstrap(), nunca run(),
//    para não disparar o dispatch HTTP de verdade.
// ---------------------------------------------------------------------
require_once 'Zend/Application.php';

$app = new Zend_Application('development', array(
    'bootstrap' => '{{BOOTSTRAP_FILE_RELATIVE}}', // ex.: 'application/Bootstrap.php'
    'phpSettings' => array(
        'error_reporting' => E_ALL & ~E_DEPRECATED & ~E_NOTICE & ~E_WARNING,
        'display_errors' => true,
        'display_startup_errors' => true,
        'date.timezone' => 'Etc/GMT+3'
    )
));

$app->bootstrap();

// ---------------------------------------------------------------------
// 3) Monta uma request/response falsa só pra satisfazer o construtor
//    de Zend_Controller_Action. Ajuste controllerName se necessário.
// ---------------------------------------------------------------------
$controllerSlug = '{{CONTROLLER_URL_SLUG}}'; // ex.: 'publicacao'

$request  = new Zend_Controller_Request_Http();
$response = new Zend_Controller_Response_Http();
$request->setModuleName('default')
    ->setControllerName($controllerSlug)
    ->setActionName($argv[1]);

// Muitos desses controllers leem $_SERVER['REQUEST_URI'] no init() pra
// extrair o nome da action a partir da URL — simula isso aqui.
$_SERVER['REQUEST_URI'] = '/' . $controllerSlug . '/' . $argv[1];

// ---------------------------------------------------------------------
// 4) Instancia o controller de publicações.
// ---------------------------------------------------------------------
$controllerClass = '{{CONTROLLER_CLASS}}'; // ex.: 'PublicacaoController'
$controllerFile  = $appPath . '{{CONTROLLER_FILE_RELATIVE}}'; // ex.: 'controllers/PublicacaoController.php'

require_once $controllerFile;
$controller = new $controllerClass($request, $response, array());

// ---------------------------------------------------------------------
// 5) Proteção para padrões multi-tenant (ex.: propriedade tipo
//    "_operadores" que faria o controller iterar sobre TODOS os
//    tenants/operadores e tentar conectar em cada banco deles).
//    Só tenta filtrar se a propriedade realmente existir — não assuma
//    que todo projeto segue esse padrão.
// ---------------------------------------------------------------------
$propriedadeMultiTenant = '{{MULTITENANT_PROPERTY_NAME}}'; // ex.: '_operadores' (deixe '' se não existir)
$campoBancoOperador      = '{{MULTITENANT_DB_FIELD}}';      // ex.: 'banco' (nome do campo com o dbname)
$prefixoBancosLocais     = '{{LOCAL_DB_PREFIX_LIKE}}';      // ex.: 'op\_%' (padrão LIKE p/ achar bancos locais)

if ($propriedadeMultiTenant !== '' && property_exists($controllerClass, $propriedadeMultiTenant)) {
    $dbAdapter = Zend_Registry::get('dbAdapter');
    $bancosLocais = $dbAdapter->fetchCol(
        "SELECT datname FROM pg_database WHERE datname LIKE '{$prefixoBancosLocais}'"
    );

    $ref = new ReflectionProperty($controllerClass, $propriedadeMultiTenant);
    $ref->setAccessible(true);
    $itens = $ref->getValue($controller);

    if (is_array($itens)) {
        $filtrados = array();
        foreach ($itens as $item) {
            $bancoDoItem = is_object($item) ? ($item->$campoBancoOperador ?? null) : ($item[$campoBancoOperador] ?? null);
            if ($bancoDoItem !== null && in_array($bancoDoItem, $bancosLocais, true)) {
                $filtrados[] = $item;
            }
        }
        $pulados = count($itens) - count($filtrados);
        $ref->setValue($controller, $filtrados);
        fwrite(STDERR, "[info] {$propriedadeMultiTenant}: " . count($filtrados)
            . " considerados, {$pulados} pulados (sem banco local)\n");
    }
}

// ---------------------------------------------------------------------
// 6) Roda as actions pedidas, na ordem informada. Para no primeiro erro
//    — não continua silenciosamente pro próximo método.
// ---------------------------------------------------------------------
foreach (array_slice($argv, 1) as $actionName) {
    $method = $actionName . 'Action';
    if (!method_exists($controller, $method)) {
        fwrite(STDERR, "[erro] Action inexistente: {$method}\n");
        exit(1);
    }

    fwrite(STDERR, "\n===> Rodando {$method} ...\n");
    try {
        $controller->$method();
        fwrite(STDERR, "===> OK: {$method}\n");
    } catch (Throwable $e) {
        fwrite(STDERR, "===> FALHOU: {$method}: " . $e->getMessage() . "\n");
        fwrite(STDERR, $e->getTraceAsString() . "\n");
        exit(1);
    }
}

fwrite(STDERR, "\nConcluido.\n");
