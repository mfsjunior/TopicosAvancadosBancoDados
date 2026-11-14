# Laboratório 09: O Abraço da Morte (Deadlocks)

## Objetivo
Reproduzir, identificar e solucionar cenários de Deadlock em bancos de dados relacionais.

## Problema
A equipe de Backend tentou rodar uma rotina de fim de dia que fecha as vagas que atingiram limite de candidaturas e, ao mesmo tempo, envia e-mails de rejeição. Por conta de um mau design nas ordens das queries, o sistema começou a explodir erros de "Deadlock Detected".

## Procedimento (Nível 1 - Execução)

O PostgreSQL possui um algoritmo de detecção nativo. Ele verifica se duas conexões entraram num estado cíclico onde a Conexão A não pode avançar pois espera por B, e B não pode avançar pois espera por A.

Vamos forçar o erro acontecer usando **dois terminais**.

**Terminal 1:**
```sql
BEGIN;
UPDATE vaga SET status = 'ENCERRADA' WHERE id = 1;
-- Travou a linha 1 da vaga. Não dê COMMIT.
```

**Terminal 2:**
```sql
BEGIN;
UPDATE vaga SET status = 'PAUSADA' WHERE id = 2;
-- Travou a linha 2 da vaga. Não dê COMMIT.
```

**Terminal 1:**
```sql
UPDATE vaga SET status = 'ENCERRADA' WHERE id = 2;
-- Vai ficar travado, porque o Terminal 2 detém o lock.
```

**Terminal 2 (Agora o Deadlock se forma):**
```sql
UPDATE vaga SET status = 'PAUSADA' WHERE id = 1;
-- O Postgres detectará o Deadlock e cancelará uma das transações (rollback forçado!).
```

Leia a mensagem de erro que aparece. Como o Postgres agiu?

## Investigação (Nível 2)
Observe nos logs do banco (ou na saída do seu terminal rodando o docker-compose) o dump de deadlock que o Postgres gera.
Ele mostra um gráfico das sessões e qual query estava bloqueando qual. Como você explicaria isso para o Desenvolvedor Back-End?

## Desafio (Nível 3)
A aplicação precisa fazer essas duas ações (alterar Vaga 1 e Vaga 2) na mesma transação. Sabendo que o deadlock ocorreu por causa da ordem cruzada (T1 atualiza 1->2 e T2 atualiza 2->1), **proponha a solução arquitetural** que todo desenvolvedor backend deve seguir ao atualizar múltiplas tabelas ou tuplas na mesma transação.

---
## Perguntas
- O que o banco ganha abortando uma das transações em vez de deixá-las esperando para sempre?
- Quem decide qual transação "sobrevive" e qual "morre" no caso do Deadlock do PostgreSQL?
