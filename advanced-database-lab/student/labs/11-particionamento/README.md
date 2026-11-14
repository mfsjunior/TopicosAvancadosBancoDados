# Laboratório 10: Particionamento de Dados em Larga Escala

## Objetivo
Resolver problemas físicos de tabelas gigantescas (com bilhões de registros) que estão impossíveis de manter e lentas, utilizando técnicas de Table Partitioning.

## Conceitos
- Tabelas Pai e Tabelas Filhas.
- Particionamento por Lista (List Partitioning).
- Particionamento por Faixa (Range Partitioning - geralmente datas).
- Partition Pruning (quando o Planner é esperto o bastante para ignorar as partições inúteis na busca).

## Problema
A tabela `candidatura` acumula todos os dados do passado histórico, bem como os registros deste ano. O tamanho em disco explodiu, os índices estão muito pesados para caber em memória (Shared Buffers), prejudicando a performance global. A diretoria quer que os dados do ano atual fiquem "quentes" e rápidos, e os dados dos anos anteriores fiquem "frios" em arquivos separados no disco, mas transparentes na hora da query.

## Procedimento (Nível 1 - Execução)

Vamos simular a criação de uma tabela particionada (Declarative Partitioning nativo do Postgres 10+).

```sql
CREATE TABLE log_candidatura (
    id SERIAL,
    candidato_id INT,
    vaga_id INT,
    status VARCHAR(50),
    data_log TIMESTAMP NOT NULL
) PARTITION BY RANGE (data_log);

-- Criando as partições filhas
CREATE TABLE log_candidatura_2023 PARTITION OF log_candidatura
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE log_candidatura_2024 PARTITION OF log_candidatura
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

Insira um registro:
```sql
INSERT INTO log_candidatura (candidato_id, vaga_id, status, data_log) 
VALUES (1, 5, 'APLICADA', '2024-05-10 10:00:00');
```
Consulte as tabelas filhas (ex: `SELECT * FROM log_candidatura_2024;`) e veja que o PostgreSQL redirecionou o INSERT perfeitamente por baixo dos panos!

## Investigação (Nível 2)
Faça um `EXPLAIN` na tabela pai (mãe) filtrando pela data:
```sql
EXPLAIN SELECT * FROM log_candidatura WHERE data_log = '2023-08-15';
```
Olhe para o plano de execução: O banco procurou as informações dentro da partição `log_candidatura_2024`? Não! Ele cortou essa partição da busca. Esse fenômeno sensacional se chama **Partition Pruning**. Como isso afeta o I/O do disco?

## Desafio (Nível 3)
A sua nova estrutura particionada está linda. Mas o desenvolvedor Júnior inseriu, acidentalmente, um registro referente ao ano futuro:
```sql
INSERT INTO log_candidatura (candidato_id, vaga_id, status, data_log) 
VALUES (1, 5, 'APLICADA', '2025-02-10 10:00:00');
```
Execute o script acima e veja o erro explodir na sua tela: *no partition of relation "log_candidatura" found for row*.
Sua missão: Como administrador de banco de dados, você precisa garantir que o sistema não dê erro se um ano "não mapeado" aparecer. Crie uma **Partição Default (Default Partition)** que absorva tudo o que não encaixar nas regras conhecidas. Forneça o script SQL de criação.

---
## Perguntas
- Na exclusão de dados antigos ("arquivar registros de 5 anos atrás"), por que um simples `DROP TABLE nome_da_particao_antiga` é trilhões de vezes mais rápido e eficiente para o disco e para o arquivo de Logs (WAL) do que realizar um `DELETE FROM tabela WHERE data < '2019'` em uma tabela enorme não-particionada?
