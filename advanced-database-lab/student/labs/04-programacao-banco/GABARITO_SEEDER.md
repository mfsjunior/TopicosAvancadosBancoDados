# Gabarito: Laboratório 4 - Extra (Evoluindo o Gerador de Dados)

Aqui estão as soluções propostas para os 3 desafios de evolução propostos na atividade extra. 

Esses scripts representam a aplicação prática dos conceitos de **Controle Transacional**, **Orquestração de Dados** e **Gatilhos (Triggers)**.

---

## Atividade 1: Controle Transacional em Lotes (COMMIT)

Para inserir registros em lotes e evitar o esgotamento de memória ou travamento da tabela (`Row Exclusive Lock`) por muito tempo, utilizamos um `LOOP` em conjunto com `OFFSET/LIMIT`, confirmando a transação (`COMMIT`) ao final de cada iteração.

**Como adaptar a sua `Procedure generate_data`:**

Adicione as variáveis de controle no bloco `DECLARE`:
```sql
    v_lote_tamanho INT := 10000;
    v_offset INT := 0;
    v_linhas_afetadas INT;
```

Substitua o trecho de geração de candidaturas por:
```sql
    RAISE NOTICE 'Gerando candidaturas em lotes de %', v_lote_tamanho;
    
    LOOP
        INSERT INTO candidatura (candidato_id, vaga_id, status)
        SELECT 
            c.id, v.id, 'APLICADA'
        FROM candidato c
        JOIN vaga v ON (c.id % v_vagas) = (v.id % v_vagas)
        LIMIT v_lote_tamanho OFFSET v_offset
        ON CONFLICT (candidato_id, vaga_id) DO NOTHING;
        
        -- Captura a quantidade de linhas que foram inseridas nesta execução do loop
        GET DIAGNOSTICS v_linhas_afetadas = ROW_COUNT;
        
        -- COMMIT do lote atual: Confirma os dados no disco e libera a memória/locks
        COMMIT; 
        
        -- Condição de saída: Se a query não retornou mais nenhuma inserção, saímos do loop
        EXIT WHEN v_linhas_afetadas = 0; 
        
        -- Incrementa o offset para buscar os próximos dados
        v_offset := v_offset + v_lote_tamanho;
    END LOOP;
```
> **Nota de Conceito:** O uso do comando `COMMIT` para liberar o processamento por lotes é um recurso exclusivo das **Procedures** no PostgreSQL. Uma `FUNCTION` não conseguiria executar esse comportamento e sofreria para processar milhões de registros.

---

## Atividade 2: Orquestração e Refresh de Views

A atualização de relatórios gerados por *Materialized Views* faz parte da rotina de cargas de dados em Data Warehouses.

**Como adaptar a sua `Procedure generate_data`:**

No final da sua Procedure, logo antes do comando `END;`, adicione o comando que força a atualização da visão materializada criada na atividade principal do laboratório:

```sql
    -- ... (Após todos os inserts e commits de dados) ...
    
    RAISE NOTICE 'Iniciando atualização da Materialized View de relatórios...';
    
    -- O comando de orquestração do banco:
    REFRESH MATERIALIZED VIEW mvw_relatorio_mensal;
    
    RAISE NOTICE 'Geração e orquestração concluídas com sucesso.';
```

---

## Atividade 3: Provando o Valor das Triggers

As Triggers oferecem garantia máxima para regras de negócio (como auditoria), independente de onde a manipulação dos dados está sendo feita.

**Script da Procedure Simuladora:**

```sql
CREATE OR REPLACE PROCEDURE pr_simulate_salary_changes(p_quantidade INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_vaga_id INT;
BEGIN
    FOR i IN 1..p_quantidade LOOP
        -- Seleciona o ID de uma vaga aleatória
        SELECT id INTO v_vaga_id FROM vaga ORDER BY random() LIMIT 1;
        
        -- Executa o UPDATE (aumenta o salário em 10%)
        -- ESTE SIMPLES COMANDO IRÁ DISPARAR A SUA TRIGGER AUTOMATICAMENTE!
        UPDATE vaga 
        SET salario = salario * 1.10 
        WHERE id = v_vaga_id;
    END LOOP;
    
    -- Confirma as alterações efetuadas
    COMMIT;
    
    RAISE NOTICE 'Simulação concluída! Foram alterados % salários.', p_quantidade;
    RAISE NOTICE 'Consulte a tabela auditoria_salario_vaga para verificar o histórico gerado pela Trigger.';
END;
$$;
```

**Executando e validando o laboratório:**

```sql
-- 1. Dispare a procedure informando quantas alterações deseja (ex: 1000)
CALL pr_simulate_salary_changes(1000);

-- 2. Consulte sua tabela de auditoria e veja que a Trigger cumpriu seu papel fielmente
SELECT * FROM auditoria_salario_vaga;
```
