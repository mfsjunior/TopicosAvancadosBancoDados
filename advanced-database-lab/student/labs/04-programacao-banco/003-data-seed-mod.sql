-- 002-data-seed.sql
-- Procedure para gerar massa de dados (SMALL, MEDIUM, LARGE)

CREATE OR REPLACE PROCEDURE generate_data(p_size VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_candidatos INT;
    v_empresas INT;
    v_vagas INT;
    v_candidaturas INT;
    v_lote_tamanho INT := 10000;
    v_offset INT := 0;
    v_linhas_afetadas INT;
BEGIN
    IF p_size = 'small' THEN
        v_candidatos := 100;
        v_empresas := 20;
        v_vagas := 50;
        v_candidaturas := 500;
    ELSIF p_size = 'medium' THEN
        v_candidatos := 10000;
        v_empresas := 1000;
        v_vagas := 5000;
        v_candidaturas := 500000;
    ELSIF p_size = 'large' THEN
        v_candidatos := 500000;
        v_empresas := 10000;
        v_vagas := 100000;
        v_candidaturas := 10000000;
    ELSIF p_size = 'million' THEN
        v_candidatos := 1000000;
        v_empresas := 20000;
        v_vagas := 100000;
        v_candidaturas := 1000000;
    ELSE
        RAISE EXCEPTION 'Tamanho inválido. Use small, medium, large ou million.';
    END IF;

    RAISE NOTICE 'Gerando dados - Nível: %', p_size;

    -- Limpando dados antigos (TRUNCATE em cascata)
    TRUNCATE TABLE empresa CASCADE;
    TRUNCATE TABLE habilidade CASCADE;
    TRUNCATE TABLE candidato CASCADE;

    -- Gerando Habilidades
    INSERT INTO habilidade (nome) VALUES 
    ('Java'), ('Python'), ('SQL'), ('PostgreSQL'), ('MongoDB'), 
    ('Docker'), ('AWS'), ('JavaScript'), ('React'), ('Node.js');

    -- Gerando Empresas
    INSERT INTO empresa (nome, cnpj, setor)
    SELECT 
        'Empresa ' || i, 
        lpad(i::text, 14, '0'), 
        (ARRAY['Tecnologia', 'Saúde', 'Finanças', 'Educação'])[floor(random() * 4 + 1)]
    FROM generate_series(1, v_empresas) i;

    -- Gerando Recrutadores (2 por empresa)
    INSERT INTO recrutador (empresa_id, nome, email)
    SELECT 
        e.id, 
        'Recrutador ' || e.id || '_' || i, 
        'recrutador' || e.id || '_' || i || '@empresa' || e.id || '.com'
    FROM empresa e
    CROSS JOIN generate_series(1, 2) i;

    -- Gerando Candidatos
    INSERT INTO candidato (nome, email, telefone, data_nascimento)
    SELECT 
        'Candidato ' || i, 
        'candidato' || i || '@email.com', 
        '1199999' || lpad((i % 10000)::text, 4, '0'),
        CURRENT_DATE - (INTERVAL '1 year' * (18 + floor(random() * 40)))
    FROM generate_series(1, v_candidatos) i;

    -- Gerando Vagas
    INSERT INTO vaga (empresa_id, recrutador_id, titulo, descricao, salario, status)
    SELECT 
        e.id,
        (SELECT id FROM recrutador WHERE empresa_id = e.id LIMIT 1 OFFSET (i % 2)),
        'Vaga para Especialista ' || i,
        'Descrição da vaga ' || i,
        floor(random() * (15000 - 3000 + 1) + 3000),
        'ABERTA'
    FROM empresa e
    CROSS JOIN generate_series(1, GREATEST(1, v_vagas / v_empresas)) i
    LIMIT v_vagas;

    -- Gerando Candidaturas em Lotes (Controle Transacional)
    RAISE NOTICE 'Gerando candidaturas em lotes de %', v_lote_tamanho;
    
    LOOP
        INSERT INTO candidatura (candidato_id, vaga_id, status)
        SELECT 
            c.id, v.id, 'APLICADA'
        FROM candidato c
        JOIN vaga v ON (c.id % v_vagas) = (v.id % v_vagas)
        LIMIT v_lote_tamanho OFFSET v_offset
        ON CONFLICT (candidato_id, vaga_id) DO NOTHING;
        
        GET DIAGNOSTICS v_linhas_afetadas = ROW_COUNT;
        
        COMMIT; 
        
        EXIT WHEN v_linhas_afetadas = 0; 
        
        v_offset := v_offset + v_lote_tamanho;
    END LOOP;

    -- Atualização da Materialized View
    RAISE NOTICE 'Atualizando a Materialized View de relatórios...';
    REFRESH MATERIALIZED VIEW mvw_relatorio_mensal;

    RAISE NOTICE 'Geração e orquestração concluídas com sucesso.';
END;
$$;

-- Na inicialização do laboratório, vamos inserir o dataset MILLION por padrão.
CALL generate_data('million');

-- =========================================================
-- Procedure: Simulação de Alteração de Salários
-- =========================================================
CREATE OR REPLACE PROCEDURE pr_simulate_salary_changes(p_quantidade INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vaga_id INT;
BEGIN
    FOR i IN 1..p_quantidade LOOP
        SELECT id INTO v_vaga_id FROM vaga ORDER BY random() LIMIT 1;
        
        UPDATE vaga 
        SET salario = salario * 1.10 
        WHERE id = v_vaga_id;
    END LOOP;
    
    COMMIT;
    
    RAISE NOTICE 'Simulação concluída! Foram alterados % salários.', p_quantidade;
    RAISE NOTICE 'Consulte a tabela auditoria_salario_vaga para verificar o histórico gerado pela Trigger.';
END;
$$;
