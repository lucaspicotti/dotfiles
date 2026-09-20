# Boas práticas de PHPUnit

Referência operacional para skills de IA que criam, alteram ou revisam testes PHP.

Baseada em [PHPUnit Best Practices (Ultimate Guide), de Loïc Faugeron](https://gnugat.github.io/2025/07/31/phpunit-best-practices.html), consultado em 20 de setembro de 2026. Adapte sempre as recomendações à versão de PHP/PHPUnit e às convenções já presentes no repositório.

## Princípios que a IA deve preservar

- Priorize testes **FIRST**: rápidos, isolados, repetíveis, auto-validáveis e escritos junto com a mudança de produção (idealmente antes dela).
- Estruture cada caso segundo **AAA**: Arrange, Act, Assert, separados por linhas em branco. Para exceções, a ordem normal é Arrange, Expect, Act.
- Teste comportamento observável, não detalhes privados de implementação. Um teste deve falhar por um motivo claro.
- Prefira legibilidade a uma abstração prematura: repetições pequenas e descritivas (DAMP) são aceitáveis quando deixam o caso mais fácil de entender. Extraia helpers apenas quando eles realmente diminuírem o custo de leitura/manutenção.
- Não introduza estado compartilhado entre testes. Testes devem passar em qualquer ordem.

## Testes unitários

- Mantenha o SUT pequeno e suas dependências sob controle; use objetos reais quando forem simples e adequados.
- Prefira métodos-fábrica `private` no teste para montar o SUT a um `setUp()` genérico. `setUp()` é executado para todo teste, inclusive os que não precisam dele; instâncias de teste e seus dados podem permanecer em memória até o fim da suíte.
- Crie fixtures explícitas, locais e mínimas. Evite boot de kernel, banco, rede ou carga pesada de fixtures em testes unitários.
- Use `assertSame()` quando a identidade/tipo também fizer parte do contrato; escolha assertions específicas em vez de asserções genéricas.
- Declare `strict_types`, torne a classe de teste `final`, use tipos e visibilidade explícitos e siga o padrão de código do projeto (PSR-4/PSR-12 se não houver outro).
- Dê nomes que expressem o comportamento. Quando o projeto adotar attributes de teste, use `#[Test]` com nomes no formato `it_...`, ou mantenha o estilo existente de maneira consistente.

Exemplo de formato:

```php
declare(strict_types=1);

#[CoversClass(Username::class)]
#[Small]
final class UsernameTest extends TestCase
{
    private function username(string $value = 'Merlin'): Username
    {
        return Username::fromString($value);
    }

    #[TestDox('Converte de e para string')]
    public function test_it_converts_from_and_to_string(): void
    {
        $this->assertSame('Merlin', $this->username()->toString());
    }
}
```

## Metadados e escopo

Para PHPUnit moderno, prefira attributes a anotações PHPDoc: anotações foram depreciadas no PHPUnit 10 e removidas no PHPUnit 12.

- `#[CoversClass(Foo::class)]`: declare a classe-alvo de um teste unitário; protege a fronteira de cobertura e deixa a intenção verificável por ferramentas.
- `#[UsesClass(Bar::class)]`: declare colaborador cujo uso é esperado, sem torná-lo alvo de cobertura.
- `#[CoversNothing]`: use em testes de integração/fluxo que não devem atribuir cobertura a uma classe específica.
- `#[Small]`: componente isolado, normalmente abaixo de 100 ms.
- `#[Medium]`: integração de componentes em isolamento, normalmente abaixo de 1 s.
- `#[Large]`: fluxo completo/end-to-end, normalmente acima de 1 s.
- `#[Group('...')]`: categoria adicional, inclusive temporária como `wip`.

Não atribua `CoversClass` por rotina: confirme qual é o alvo e use `CoversNothing` se o teste validar um fluxo transversal.

## Casos parametrizados e especificação executável

- Para vários exemplos de entrada/saída, use `#[DataProvider('methodName')]` com método `public static`; use `#[DataProviderExternal(...)]` quando os dados pertencem a outra classe.
- Para um único conjunto pequeno de dados, `#[TestWith([...])]` pode ser mais direto.
- Prefira providers com `yield`, conjuntos nomeados e uma coluna `scenario`. Isso melhora a falha e o TestDox.
- Use `#[TestDox('...')]` quando o nome técnico não for uma boa frase de especificação. Valide a leitura com `--testdox`.

```php
#[DataProvider('invalidUsernameProvider')]
#[TestDox('Falha quando o username $scenario')]
public function test_it_rejects_invalid_username(string $scenario, string $value): void
{
    $this->expectException(ValidationFailedException::class);

    $this->username($value);
}

public static function invalidUsernameProvider(): \Iterator
{
    yield ['scenario' => 'está vazio', 'value' => ''];
    yield ['scenario' => 'é curto demais', 'value' => 'abc'];
}
```

## Dublês, stubs e mocks

- Primeiro considere objetos reais. Use mocks para descrever/verificar uma interação relevante entre SUT e colaborador, não como padrão automático.
- Um **stub** fornece uma resposta necessária para o SUT avançar; um **mock** verifica que uma interação esperada ocorreu. Não misture os papéis sem necessidade.
- Ao testar valor criado internamente pelo SUT, prefira matchers por tipo ou predicado a comparar uma instância impossível de reutilizar. Em Prophecy: `Argument::type()`, `Argument::that()` e, com parcimônia, `Argument::any()`.
- Não simule o que não pertence ao sistema/equipe quando houver alternativa confiável (adaptador próprio, fake ou teste de integração).
- Evite expectativas de chamadas que não representem contrato observável: elas acoplam o teste à implementação e bloqueiam refactors legítimos.

## Integração e smoke tests

- Marque testes de integração como `#[Medium]` e normalmente `#[CoversNothing]`.
- Reconheça custos que se multiplicam por método e por linha de data provider: boot repetido de kernel, conexões de banco, hidratação de fixtures e APIs externas.
- Reaproveite somente serviços de aplicação sem estado quando for seguro; limpe banco com transações; substitua dependências externas por dublês controlados.
- Para controllers e comandos, prefira um smoke test pragmático: envie uma entrada realista pela borda pública e valide o status/resultado principal. Não replique em integração as regras de negócio já cobertas em unidade.
- Inclua o conteúdo de resposta como mensagem de falha quando ajudar a diagnosticar, por exemplo no `assertSame()` do status HTTP.

## Configuração recomendada

Ao criar ou revisar `phpunit.xml`, preserve as escolhas existentes do repositório. Quando apropriado, a configuração deve separar suítes unitária e de integração, incluir apenas código de produção como fonte e tornar problemas visíveis cedo:

```xml
<phpunit
    bootstrap="tests/bootstrap.php"
    cacheDirectory=".phpunit.cache"
    executionOrder="depends,defects"
    requireCoverageMetadata="true"
    beStrictAboutCoverageMetadata="true"
    beStrictAboutOutputDuringTests="true"
    displayDetailsOnPhpunitDeprecations="true"
    failOnPhpunitDeprecation="true"
    failOnRisky="true"
    failOnWarning="true"
>
    <testsuites>
        <testsuite name="unit"><directory>tests/Unit</directory></testsuite>
        <testsuite name="integration"><directory>tests/Integration</directory></testsuite>
    </testsuites>
    <source><include><directory>src</directory></include></source>
</phpunit>
```

Antes de propor esses flags, confirme suporte pela versão instalada: XML e opções variam entre versões. `bootstrap` normalmente pode ser omitido se `vendor/autoload.php` bastar.

## Execução e diagnóstico

Use o comando real do projeto (por exemplo, `vendor/bin/phpunit`, Composer script ou container). Opções úteis:

- `--testsuite unit` / `--testsuite integration`: rode uma suíte específica, especialmente em CI.
- `--filter 'NomeDoTeste'` ou `--covers 'Classe'`: itere em um alvo estreito.
- `--group small` e `--exclude-group small`: selecione por custo/escopo.
- `--testdox`: revise a suíte como especificação legível.
- `--stop-on-failure`: acelere o diagnóstico local.
- `--order-by=depends,defects`: execute dependências corretamente e antecipe falhas já conhecidas (com cache de resultados).
- `--order-by=random --random-order-seed <n>`: detecte acoplamento entre testes e reproduza uma ordem problemática.
- `--order-by=size`: exponha a distribuição de custo por tamanho.
- `--list-tests`, `--list-groups` e `--list-testsuites`: descubra a configuração efetiva antes de assumir nomes.

## Checklist para uma skill de IA

Antes de finalizar uma mudança em testes PHPUnit, verificar:

1. O caso valida um comportamento/contrato e tem um único motivo principal para falhar?
2. O teste é independente de ordem, tempo, rede e estado persistente desnecessário?
3. A classificação (`Small`/`Medium`/`Large`) e os metadados de cobertura refletem o escopo real?
4. A montagem é mínima e explícita, sem `setUp()` caro ou genérico?
5. Data providers, nomes e TestDox tornam as variações compreensíveis?
6. Mocks verificam somente interações contratuais relevantes?
7. O teste segue as convenções e a versão de PHPUnit já adotadas no repositório?
8. Foi executado pelo menos o teste/suíte afetado, usando o comando do projeto?

