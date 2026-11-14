-- Script de carga para a Aula 04: Pesquisa sem Índice vs Com Índice
-- pgbench injeta um ID aleatório entre 1 e 500.000 a cada conexão/iteração
\set id random(1, 500000)

-- Montando a string de busca por email
-- (A maioria vai dar "Not Found" se o ID for maior que o volume gerado, mas ainda assim forçará o SCAN)
SELECT * FROM candidato WHERE email = 'candidato' || :id || '@email.com';
