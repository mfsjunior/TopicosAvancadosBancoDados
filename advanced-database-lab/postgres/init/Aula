SELECT 
    titulo, 
    salario,
    CASE 
        WHEN status = 'ABERTA' THEN 'Buscando Candidatos'
        WHEN status = 'PAUSADA' THEN 'Em espera'
        ELSE 'Processo Encerrado'
    END as status_traduzido
FROM vaga
LIMIT 10;