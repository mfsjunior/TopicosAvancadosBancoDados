# Laboratório 07: Transações e Isolamento

## Objetivo
Entender na prática o que significa a letra 'I' (Isolamento) do princípio ACID em sistemas concorrentes e como as transações previnem leituras sujas e anomalias de banco.

## Conceitos
- Controle Transacional (`BEGIN`, `COMMIT`, `ROLLBACK`)
- Níveis de Isolamento (Read Committed, Repeatable Read, Serializable)
- Anomalias: Dirty Read, Non-Repeatable Read, Phantom Read.

## Procedimento (Nível 1 - Execução)

Você precisará de **dois terminais** abertos lado a lado.
Em ambos os terminais, conecte-se ao banco:
```bash
docker exec -it adv_db_postgres psql -U adv_user -d adv_recruitment
```

**Terminal 1 (Sessão A)**
```sql
BEGIN;
UPDATE vaga SET salario = 15000 WHERE id = 1;
-- Não faça o COMMIT ainda!
```

**Terminal 2 (Sessão B)**
```sql
SELECT salario FROM vaga WHERE id = 1;
```

O Terminal B enxerga o novo salário de 15000? Por que não? Isso é o nível de isolamento padrão do PostgreSQL (Read Committed) impedindo uma *Dirty Read* (Leitura Suja).

**Terminal 1 (Sessão A)**
```sql
COMMIT;
```

**Terminal 2 (Sessão B)**
```sql
SELECT salario FROM vaga WHERE id = 1;
```
Agora o Terminal B enxerga o dado.

## Investigação (Nível 2)

Ainda usando os dois terminais:
**Terminal 1:**
```sql
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT salario FROM vaga WHERE id = 2; -- Anote o valor
```
**Terminal 2:**
```sql
UPDATE vaga SET salario = 99999 WHERE id = 2;
```
**Terminal 1:**
```sql
SELECT salario FROM vaga WHERE id = 2; -- Repita o select
```
Explique por que o Terminal 1 continua vendo o valor antigo, mesmo após o Terminal 2 já ter feito o Update de maneira auto-commitada. O que o modo `REPEATABLE READ` garante?

## Desafio (Nível 3)
Crie um cenário prático (com código SQL para Sessão A e Sessão B) onde a anomalia do tipo **Phantom Read** (Leitura Fantasma) pode acontecer, e como resolvê-la subindo o isolamento para `SERIALIZABLE`. Lembre-se: *Phantom read* envolve inserção de novas linhas, não apenas alteração de linhas existentes.

---
## Perguntas
- O que é o princípio da Atomicidade no conceito ACID? O que acontece fisicamente quando fazemos um `ROLLBACK`?
- Por que os bancos de dados modernos não rodam todas as queries em nível `SERIALIZABLE` se ele é o mais seguro de todos?
