# Laboratório 08: MVCC e Locks

## Objetivo
Entender como o Multiversion Concurrency Control (MVCC) permite que leitores não bloqueiem escritores (e vice-versa), e como diagnosticar quando um processo fica preso por outro.

## Conceitos
- Locks (Bloqueios) a nível de tabela (RowShareLock, AccessExclusiveLock)
- Locks a nível de linha
- Visualização de atividades na view `pg_stat_activity`
- `SELECT FOR UPDATE`

## Procedimento (Nível 1 - Execução)

Em **dois terminais**:

**Terminal 1:**
```sql
BEGIN;
UPDATE vaga SET salario = 5000 WHERE id = 10;
-- Não dê COMMIT.
```

**Terminal 2:**
```sql
BEGIN;
UPDATE vaga SET status = 'PAUSADA' WHERE id = 10;
-- O terminal ficará travado aguardando!
```

O Terminal 2 não consegue alterar a linha, pois o Terminal 1 detém o "Row-level Lock" exclusivo daquela tupla (linha).

## Investigação (Nível 2)
Como um DBA descobre quem está travando quem no sistema de produção?
Abra um **Terminal 3**:
Execute esta query clássica de diagnóstico:
```sql
SELECT 
    pid, 
    usename, 
    pg_blocking_pids(pid) as blocked_by, 
    query as blocked_query
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;
```
Encontre o ID do Processo (PID) que está travado e qual PID está causando o travamento.

Volte ao Terminal 1 e rode `ROLLBACK;`. Observe como o Terminal 2 imediatamente "descongela" e aplica a alteração.

## Desafio (Nível 3)
Em um sistema de candidaturas muito disputado, 10 candidatos podem tentar aplicar para a ÚLTIMA vaga restante simultaneamente (caso a regra de negócio determinasse vagas limitadas, como assentos de um teatro). 
Como o banco previne que a aplicação no código Backend não sofra *race conditions* (condições de corrida) e leia que a vaga ainda existe, permitindo 10 inscrições acima do limite?
**Tarefa:** Explique e demonstre na prática o uso do `SELECT ... FOR UPDATE` como padrão para lidar com concorrências em transações críticas financeiras ou de limitação física.

---
## Perguntas
- "Leitores não bloqueiam Escritores". Como a tecnologia MVCC torna essa frase realidade no PostgreSQL ao invés de colocar um Lock explícito na tabela inteira durante um SELECT?
