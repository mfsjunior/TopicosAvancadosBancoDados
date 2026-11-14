-- Script de carga para a Aula 06: JOIN Pesado 
-- Testa a performance de ler Tabelas Relacionais interligadas (Painel do Recrutador)
\set id random(1, 1000)

SELECT 
    r.nome AS recrutador,
    e.nome AS empresa,
    COUNT(v.id) AS total_vagas_abertas
FROM recrutador r
JOIN empresa e ON r.empresa_id = e.id
LEFT JOIN vaga v ON v.recrutador_id = r.id AND v.status = 'ABERTA'
WHERE r.id = :id
GROUP BY r.nome, e.nome;
