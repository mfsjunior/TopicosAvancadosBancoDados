# Laboratório 4 - Aplicação Prática: Construindo e Evoluindo o Gerador de Dados

Nesta atividade extra, vamos analisar como a Procedure `generate_data` foi construída para popular o banco de dados com uma massa de testes. Em seguida, você aplicará os conceitos aprendidos (Transações em Procedures, Materialized Views e Triggers) para evoluir esse script.

---

## Parte 1: Passo a Passo - Entendendo o Seed

O script de geração de dados utiliza conceitos avançados do PostgreSQL para inserir milhares de registros sem a necessidade de comandos manuais repetitivos.

### 1. A Estrutura da Procedure e Variáveis
A "casca" da Procedure recebe um parâmetro de tamanho (`small`, `medium`, `large`) e, com base nisso, define quantas linhas de cada tabela vamos gerar usando a estrutura de controle `IF/ELSIF`.

```sql
CREATE OR REPLACE PROCEDURE generate_data(p_size VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variáveis para controlar a quantidade de dados
    v_candidatos INT;
    v_empresas INT;
    v_vagas INT;
BEGIN
    IF p_size = 'small' THEN
        v_candidatos := 100;
        v_empresas := 20;
        v_vagas := 50;
    ELSIF p_size = 'large' THEN
        -- Simulando uma carga de stress!
        v_candidatos := 500000;
        v_empresas := 10000;
        v_vagas := 100000;
    ELSE
        RAISE EXCEPTION 'Tamanho inválido. Use small ou large.';
    END IF;
    
    RAISE NOTICE 'Iniciando geração de dados - Tamanho: %', p_size;
    
    -- O resto do código (inserts) vai aqui...
END;
$$;
```

### 2. O comando "Apagar Tudo" (TRUNCATE)
Antes de gerar novos dados, limpamos a base. Diferente do `DELETE` (que apaga linha a linha de forma transacional e mais lenta), o `TRUNCATE` zera a tabela quase instantaneamente. O `CASCADE` garante que as tabelas filhas (chaves estrangeiras) também sejam limpas.

```sql
    -- Limpando dados antigos rapidamente
    TRUNCATE TABLE empresa CASCADE;
    TRUNCATE TABLE candidato CASCADE;
```

### 3. O poder da multiplicação com `generate_series`
Para gerar 100 empresas sem fazer 100 `INSERT`s manuais, usamos a função nativa `generate_series(inicio, fim)`.

```sql
    -- Gerando Empresas
    INSERT INTO empresa (nome, cnpj, setor)
    SELECT 
        'Empresa ' || i,  -- Concatena o texto com o número (Empresa 1, Empresa 2...)
        lpad(i::text, 14, '0'), -- Completa com zeros à esquerda até ter 14 dígitos
        (ARRAY['Tecnologia', 'Saúde', 'Finanças'])[floor(random() * 3 + 1)] -- Sorteia um setor
    FROM generate_series(1, v_empresas) i;
```

### 4. Cruzando Tabelas (`CROSS JOIN`)
Para garantir que toda empresa recém-criada receba exatamente 2 recrutadores, usamos o `CROSS JOIN` multiplicando as empresas geradas por 2.

```sql
    -- Gerando 2 Recrutadores por empresa existente
    INSERT INTO recrutador (empresa_id, nome, email)
    SELECT 
        e.id, 
        'Recrutador ' || e.id || '_' || i, 
        'recrutador' || e.id || '_' || i || '@empresa' || e.id || '.com'
    FROM empresa e
    CROSS JOIN generate_series(1, 2) i;
```

### 5. Lidando com duplicidade (`ON CONFLICT`)
Ao cruzar candidatos e vagas aleatoriamente para gerar as candidaturas, o mesmo candidato pode tentar aplicar para a mesma vaga duas vezes (violando a chave única). O comando `ON CONFLICT DO NOTHING` instrui o banco a ignorar o erro silenciosamente e prosseguir.

```sql
    -- Gerando Candidaturas Aleatórias
    INSERT INTO candidatura (candidato_id, vaga_id, status)
    SELECT 
        c.id, v.id, 'APLICADA'
    FROM candidato c
    JOIN vaga v ON (c.id % v_vagas) = (v.id % v_vagas)
    LIMIT 500
    ON CONFLICT (candidato_id, vaga_id) DO NOTHING;
```

---

## Parte 2: Aplicando os Conceitos do LAB 4 no Seed

Agora que você entendeu o funcionamento da Procedure de dados, aplique o que aprendeu no laboratório principal para evoluí-la.

### Atividade 1: Controle Transacional em Lotes (COMMIT)
No código atual, se a geração falhar no meio de uma carga `large` (que insere milhões de registros), a procedure inteira sofre `ROLLBACK` e a memória do servidor pode ser sobrecarregada.

**Tarefa:** Modifique a Procedure de geração de dados para que a inserção massiva (ex: `candidatura`) aconteça dentro de um `LOOP`, realizando um `COMMIT` a cada 10.000 registros inseridos. 
*Objetivo:* Aplicar na prática o uso do `COMMIT` em blocos, diferencial fundamental de uma `PROCEDURE` em relação a uma `FUNCTION`.

### Atividade 2: Orquestração e Refresh de Views
Durante a carga de novos dados (`generate_data`), qualquer `MATERIALIZED VIEW` existente (como a de relatórios gerada no lab principal) ficará com dados velhos (defasados).

**Tarefa:** Edite a Procedure `generate_data` adicionando uma instrução ao final (antes do `END;`) para que ela invoque automaticamente o comando `REFRESH MATERIALIZED VIEW` na sua visão de relatórios.
*Objetivo:* Entender como Procedures são utilizadas em fluxos de engenharia de dados (pipelines) para atualizar data marts e relatórios de forma orquestrada.

### Atividade 3: Provando o Valor das Triggers
No laboratório principal, você criou uma Trigger que audita qualquer mudança de salário (`trg_audita_salario`). Vamos testar se ela é à prova de falhas, mesmo em mudanças massivas em lote.

**Tarefa:** Crie uma nova Procedure chamada `pr_simulate_salary_changes(p_quantidade INT)`. 
Ela deve fazer um `UPDATE` no salário de vagas aleatórias (por exemplo, aplicando um aumento de 10%). Ao rodar `CALL pr_simulate_salary_changes(1000);`, verifique a sua tabela `auditoria_salario_vaga`. Ela deve ter recebido 1000 novos registros de histórico **automaticamente**, sem que o script de UPDATE soubesse da existência da auditoria.
*Objetivo:* Provar visualmente o valor de uma Trigger para garantir regras de negócio inquebráveis e rastreabilidade assíncrona.
