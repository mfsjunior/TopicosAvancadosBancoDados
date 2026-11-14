# Laboratório 06: Performance Investigation

## Objetivo
Diagnosticar um problema real de lentidão de ponta a ponta. Você receberá uma reclamação de usuário, investigará e proporá a solução usando os conhecimentos de Índices e EXPLAIN.

## Problema
"O painel do recrutador está muito lento. Quando um recrutador entra no sistema, o banco precisa buscar o Nome do Recrutador, o Nome da Empresa onde ele trabalha e a quantidade de Vagas Abertas que ele gerencia no momento."

## Procedimento (Nível 1 - Execução)

Execute a query lenta:
```sql
EXPLAIN ANALYZE
SELECT 
    r.nome AS recrutador,
    e.nome AS empresa,
    COUNT(v.id) AS total_vagas_abertas
FROM recrutador r
JOIN empresa e ON r.empresa_id = e.id
LEFT JOIN vaga v ON v.recrutador_id = r.id AND v.status = 'ABERTA'
WHERE r.id = 15
GROUP BY r.nome, e.nome;
```

## Investigação (Nível 2)
Identifique o Gargalo.
Leia o plano de execução. Provavelmente você verá Scans pesados na tabela de Vagas.
Onde está o problema de performance? O Join? A Agregação? Ou a falta de acesso rápido aos registros da vaga associados a esse recrutador?

## Desafio (Nível 3) - Tuning
Crie a estrutura de índices necessária para fazer essa consulta rodar em menos de `1ms` (ou o mínimo possível em sua máquina local). 
Registre no seu relatório:
- ANTES: Tempo e Plano (Identificação do gargalo principal: Seq Scan? Hash Join pesado?)
- SOLUÇÃO: O comando SQL de criação do índice.
- DEPOIS: Tempo e Plano comprovando que o gargalo sumiu (Mudou para Nested Loop com Index Scan?).

---
## Perguntas
- Por que a ausência de um índice em uma Chave Estrangeira (FK), como o `recrutador_id` na tabela `vaga`, pode causar lentidões mortais em JOINs relacionais? (Lembre-se que por padrão o Postgres não cria índices em FKs!).
