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
    v_batch_size INT := 100000;
    i INT;
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
        v_candidatos := 10000000; -- 10 milhões
        v_empresas := 100000;     -- 100 mil
        v_vagas := 500000;        -- 500 mil
        v_candidaturas := 10000000; -- 10 milhões
    ELSE
        RAISE EXCEPTION 'Tamanho inválido. Use small, medium ou large.';
    END IF;

    RAISE NOTICE 'Gerando dados - Nível: %', p_size;

    -- Limpando dados antigos (TRUNCATE em cascata + Reset de IDs)
    TRUNCATE TABLE empresa RESTART IDENTITY CASCADE;
    TRUNCATE TABLE habilidade RESTART IDENTITY CASCADE;
    TRUNCATE TABLE candidato RESTART IDENTITY CASCADE;

    -- Gerando Habilidades
    INSERT INTO habilidade (nome) VALUES 
    ('Java'), ('Python'), ('SQL'), ('PostgreSQL'), ('MongoDB'), 
    ('Docker'), ('AWS'), ('JavaScript'), ('React'), ('Node.js');
    COMMIT;

    -- Gerando Empresas em lotes
    RAISE NOTICE 'Gerando Empresas...';
    FOR i IN 0..(v_empresas / v_batch_size) LOOP
        IF i * v_batch_size >= v_empresas THEN EXIT; END IF;
        
        INSERT INTO empresa (nome, cnpj, setor)
        SELECT 
            'Empresa ' || ((i * v_batch_size) + j), 
            lpad(((i * v_batch_size) + j)::text, 14, '0'), 
            (ARRAY['Tecnologia', 'Saúde', 'Finanças', 'Educação'])[floor(random() * 4 + 1)]
        FROM generate_series(1, LEAST(v_batch_size, v_empresas - (i * v_batch_size))) j;
        COMMIT;
    END LOOP;

    -- Gerando Recrutadores em lotes
    RAISE NOTICE 'Gerando Recrutadores...';
    FOR i IN 0..(v_empresas / v_batch_size) LOOP
        IF i * v_batch_size >= v_empresas THEN EXIT; END IF;
        
        INSERT INTO recrutador (empresa_id, nome, email)
        SELECT 
            e_id, 
            'Recrutador ' || e_id || '_' || r, 
            'recrutador' || e_id || '_' || r || '@empresa' || e_id || '.com'
        FROM generate_series((i * v_batch_size) + 1, LEAST((i + 1) * v_batch_size, v_empresas)) e_id
        CROSS JOIN generate_series(1, 2) r;
        COMMIT;
    END LOOP;

    -- Gerando Candidatos em lotes
    RAISE NOTICE 'Gerando Candidatos...';
    FOR i IN 0..(v_candidatos / v_batch_size) LOOP
        IF i * v_batch_size >= v_candidatos THEN EXIT; END IF;
        
        INSERT INTO candidato (nome, email, telefone, data_nascimento)
        SELECT 
            'Candidato ' || ((i * v_batch_size) + j), 
            'candidato' || ((i * v_batch_size) + j) || '@email.com', 
            '1199999' || lpad((((i * v_batch_size) + j) % 10000)::text, 4, '0'),
            CURRENT_DATE - (INTERVAL '1 year' * (18 + floor(random() * 40)))
        FROM generate_series(1, LEAST(v_batch_size, v_candidatos - (i * v_batch_size))) j;
        COMMIT;
    END LOOP;

    -- Gerando Vagas em lotes
    RAISE NOTICE 'Gerando Vagas...';
    FOR i IN 0..(v_vagas / v_batch_size) LOOP
        IF i * v_batch_size >= v_vagas THEN EXIT; END IF;
        
        INSERT INTO vaga (empresa_id, recrutador_id, titulo, descricao, salario, status)
        SELECT 
            e_id,
            -- Relaciona diretamente o recrutador sabendo que existem 2 por empresa
            (e_id * 2) - (j % 2),
            'Vaga para Especialista ' || ((i * v_batch_size) + j),
            'Descrição da vaga ' || ((i * v_batch_size) + j),
            floor(random() * (15000 - 3000 + 1) + 3000),
            'ABERTA'
        FROM (
            SELECT 
                j, 
                ((((i * v_batch_size) + j) - 1) % v_empresas) + 1 AS e_id
            FROM generate_series(1, LEAST(v_batch_size, v_vagas - (i * v_batch_size))) j
        ) sub;
        COMMIT;
    END LOOP;

    -- Gerando Candidaturas em lotes
    RAISE NOTICE 'Gerando Candidaturas...';
    FOR i IN 0..(v_candidaturas / v_batch_size) LOOP
        IF i * v_batch_size >= v_candidaturas THEN EXIT; END IF;
        
        INSERT INTO candidatura (candidato_id, vaga_id, status)
        SELECT 
            ((((i * v_batch_size) + j) - 1) % v_candidatos) + 1, 
            ((((i * v_batch_size) + j) * 7) % v_vagas) + 1, 
            (ARRAY['APLICADA', 'EM_ANALISE', 'ENTREVISTA', 'REJEITADA'])[floor(random() * 4 + 1)]
        FROM generate_series(1, LEAST(v_batch_size, v_candidaturas - (i * v_batch_size))) j
        ON CONFLICT (candidato_id, vaga_id) DO NOTHING;
        COMMIT;
    END LOOP;

    RAISE NOTICE 'Geração concluída com sucesso.';
END;
$$;

-- Na inicialização do laboratório, vamos inserir o dataset LARGE por padrão.
CALL generate_data('large');
