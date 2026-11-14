# Tipos de Dados em PostgreSQL e PL/pgSQL

O PostgreSQL possui um conjunto muito rico de tipos de dados nativos. O PL/pgSQL (sua linguagem procedural) suporta todos os tipos do SQL do PostgreSQL, além de adicionar alguns tipos específicos para a estruturação de blocos de código.

## 1. Tipos de Dados do SQL (PostgreSQL)

Esses tipos são usados na definição de colunas em tabelas e também podem ser usados como variáveis em funções PL/pgSQL.

### 1.1. Tipos Numéricos
*   **`smallint` (ou `int2`)**: Inteiro com sinal de 2 bytes (-32768 a +32767).
*   **`integer` (ou `int`, `int4`)**: Inteiro com sinal de 4 bytes (-2 bilhões a +2 bilhões). É a escolha padrão comum.
*   **`bigint` (ou `int8`)**: Inteiro com sinal de 8 bytes (para números gigantescos).
*   **`decimal` e `numeric`**: Números com precisão arbitrária exata. Recomendado para valores monetários ou onde a precisão é crítica. Ex: `numeric(10, 2)`.
*   **`real` (ou `float4`)**: Ponto flutuante de precisão simples (4 bytes, ~6 dígitos decimais).
*   **`double precision` (ou `float8`)**: Ponto flutuante de precisão dupla (8 bytes, ~15 dígitos decimais).
*   **Tipos Seriais (Autoincremento)**: 
    *   **`smallserial`**: Auto-incremento de 2 bytes.
    *   **`serial`**: Auto-incremento de 4 bytes.
    *   **`bigserial`**: Auto-incremento de 8 bytes.
    *(Nota: Nas versões mais recentes do PostgreSQL, recomenda-se o uso de `GENERATED ALWAYS AS IDENTITY` no lugar dos tipos serial).*

### 1.2. Tipos de Caracteres (Strings)
*   **`varchar(n)` (ou `character varying(n)`)**: String de tamanho variável com limite `n`. Se `n` não for especificado, aceita strings de qualquer tamanho.
*   **`char(n)` (ou `character(n)`)**: String de tamanho fixo. Preenche o espaço restante com espaços em branco à direita.
*   **`text`**: String de tamanho variável ilimitado. É equivalente ao `varchar` sem limite de tamanho e é **altamente recomendado** no PostgreSQL por não ter custo extra de performance.

### 1.3. Tipos de Data e Hora
*   **`date`**: Armazena a data (ano, mês e dia).
*   **`time [without time zone]`**: Armazena a hora do dia (sem fuso horário).
*   **`time with time zone` (ou `timetz`)**: Armazena a hora do dia incluindo o fuso horário.
*   **`timestamp [without time zone]`**: Armazena data e hora sem fuso horário.
*   **`timestamp with time zone` (ou `timestamptz`)**: Armazena data e hora, adaptando para o fuso horário (muito recomendado para aplicações globais).
*   **`interval`**: Armazena intervalos de tempo (ex: `3 days 12 hours 30 minutes`).

### 1.4. Tipo Booleano
*   **`boolean` (ou `bool`)**: Armazena `true`, `false` ou nulo (`NULL`). Suporta literais de string para facilitar (ex: `'t'`, `'true'`, `'y'`, `'yes'`, `'1'` para verdadeiro).

### 1.5. Tipos Binários
*   **`bytea`**: Armazena arrays de bytes (dados binários crus, como imagens, arquivos). Funciona como o `BLOB` em outros bancos.

### 1.6. Tipos Documentais (JSON e XML)
*   **`json`**: Armazena dados JSON em formato de texto, verificando a validade no momento de salvar.
*   **`jsonb`**: Armazena dados JSON em um formato binário indexável, muito mais rápido para processamento e pesquisas, embora ligeiramente mais lento para inserir. É o padrão da indústria no Postgres.
*   **`xml`**: Usado para armazenar dados XML validados.

### 1.7. Tipos de Rede (Network Addresses)
*   **`inet` e `cidr`**: Armazenam endereços IPv4 e IPv6 e redes.
*   **`macaddr` e `macaddr8`**: Armazenam endereços MAC.

### 1.8. UUID
*   **`uuid`**: Armazena identificadores únicos universais (ex: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`).

### 1.9. Arrays
*   **Arrays de qualquer tipo**: No PostgreSQL, praticamente qualquer tipo de dado tem sua versão em Array (ex: `integer[]`, `text[][]`). Você pode ter arrays de inteiros, strings, JSON, etc.

### 1.10. Tipos Geométricos
*   **`point`, `line`, `lseg`, `box`, `path`, `polygon`, `circle`**: Usados para representar dados espaciais e em 2D nativamente (frequentemente estendido por extensões como *PostGIS*).

### 1.11. Tipos de Range (Intervalos)
*   Representam intervalos de valores: `int4range`, `int8range`, `numrange`, `tsrange` (timestamp), `tstzrange`, `daterange`.

---

## 2. Tipos de Dados Específicos do PL/pgSQL

Quando você programa rotinas com `LANGUAGE plpgsql`, tem acesso a todos os tipos acima mais alguns que são específicos para a construção da lógica do programa.

### 2.1. Tipos de Registros (Records e Row Types)
Esses tipos ajudam a armazenar linhas inteiras resultantes de consultas SQL (`SELECT`).

*   **`RECORD`**: Um tipo genérico e flexível que não tem uma estrutura predefinida fixa. Ele assume a estrutura da linha que lhe for atribuída (útil para loops genéricos `FOR`).
*   **`ROWTYPE` (Ex: `tabela%ROWTYPE`)**: Uma variável deste tipo tem exatamente os mesmos campos que as colunas de uma determinada tabela (estrutura rígida e validada na compilação).

### 2.2. O Atributo de Ancoragem (`%TYPE`)
*   **`%TYPE` (Ex: `variavel tabela.coluna%TYPE`)**: Muito semelhante ao Oracle. É usado na declaração de variáveis para copiar automaticamente o tipo de dado de uma coluna de uma tabela existente ou outra variável. Se o tipo da coluna mudar na tabela (ex: de int4 para int8), a função PL/pgSQL se adapta automaticamente sem precisar reescrever o código.

### 2.3. Tipos de Cursor
*   **`refcursor`**: Um cursor serve para encapsular uma query e permitir navegar por seus resultados iterativamente linha a linha, reduzindo o uso de memória em pesquisas muito grandes. `refcursor` é um tipo de dado genérico que pode ser usado para retornar cursores a partir de funções.

### 2.4. Tipo `ALIAS`
Em funções PL/pgSQL, você pode definir que uma variável seja um alias (um apelido) de outra, algo que é bastante útil para dar nomes significativos para parâmetros passados em arrays de argumentos, como em triggers (`NEW` e `OLD`, que são do tipo `RECORD`).
