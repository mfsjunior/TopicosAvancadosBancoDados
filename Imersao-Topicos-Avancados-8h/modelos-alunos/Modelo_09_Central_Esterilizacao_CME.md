# Modelo 09: Central de Esterilização de Materiais (CME) e Rastreabilidade

**Domínio:** Biossegurança, Central de Esterilização e Gestão de Instrumentais Cirúrgicos  
**Complexidade:** Alta (Rastreabilidade Unitária de Pinças, Ciclos Térmicos em Autoclaves e Testes Biológicos)

---

## 📌 1. Cenário de Negócio
A Central de Material e Esterilização (CME) é o coração da segurança cirúrgica hospitalar:
* Recebe instrumentais sujos do Bloco Cirúrgico, realiza lavagem ultrassônica, termodesinfecção, montagem de **Kits Cirúrgicos** (ex: Caixa de Laparotomia com 50 pinças e bisturis específicos) e embalagem em grau cirúrgico.
* Os kits são colocados em **Autoclaves a Vapor** sob ciclos de pressão (2.2 bar) e temperatura (134ºC) por tempos rigorosamente controlados.
* Cada ciclo exige **Indicadores Químicos de Classe 5/6** e **Indicadores Biológicos com esporos (*Geobacillus stearothermophilus*)** para garantir esterilidade absoluta.
* Cada kit recebe uma etiqueta com código de barras, data/hora do ciclo, número do lote e data de validade de esterilização.
* Se um teste biológico do ciclo der positivo (falha na esterilização), **todos os kits daquele ciclo devem ser recolhidos e bloqueados imediatamente no sistema**.

---

## 📄 2. Planilha Bruta de Entrada (`dados_cme_esterilizacao.csv`)

Abaixo está o extrato exportado do sistema de controle de esterilização da CME (delimitador: ponto e vírgula `;`):

```csv
ID_Ciclo_CME;Data_Hora_Ciclo;Autoclave_ID;Temperatura_Maxima;Pressao_Bar;Operador_CME_Matricula;Nome_Operador;Kits_Esterilizados_Codigos_Descricao;Indicador_Biologico_Lote_Resultado;Data_Validade_Esterilizacao;Setor_Destino_Alocado;Status_Ciclo
1001;29/10/2023 06:00;Autoclave Vapor 01 (CISA);134.5 C;2.18 bar;MAT-5544;Téc. Valter Cruz;"KIT-LAP-01 (Caixa Laparotomia, 48 pinças), KIT-HER-02 (Caixa Hérnia, 25 pinças), KIT-APEND-03 (Caixa Apêndice, 30 pinças)";Lote BIO-998 (Resultado: Negativo - Aprovado);29/11/2023;Bloco Cirúrgico - Arsenal Estéril;Aprovado e Liberado
1002;29/10/2023 07:30;Autoclave Vapor 02 (Baumer);134.0 C;2.15 bar;MAT-5544;Téc. Valter Cruz;"KIT-CARD-05 (Caixa Cirurgia Cardíaca, 60 pinças titânio), KIT-VASC-01 (Caixa Vascular, 35 pinças)";Lote BIO-998 (Resultado: Negativo - Aprovado);29/11/2023;Bloco Cirúrgico - Sala 03;Aprovado e Liberado
1003;29/10/2023 09:00;Autoclave Vapor 01 (CISA);128.0 C [ABAIXO!];1.80 bar [FALHA PRESSÃO];MAT-6677;Téc. Eliana Santos;"KIT-PARTO-01 (Caixa Fórceps, 18 pinças), KIT-PEQ-04 (Caixa Pequena Cirurgia, 15 pinças)";Lote BIO-999 (Resultado: Em Incubação 24h);29/11/2023;Quarentena CME;Ciclo Abortado por Falha Térmica
1004;29/10/2023 11:00;Termodesinfectadora 01;93.0 C;1.00 bar;MAT-6677;Téc. Eliana Santos;"Kits em Lavagem e Desinfecção Térmica Prévia";N/A;N/A;Expedição CME;Em Processamento
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Equipamento_Autoclave`, `Operador_CME`, `Ciclo_Esterilizacao`, `Indicador_Biologico`, `Kit_Cirurgico` e `Instrumental_Item`.
   * Restrições `CHECK (Temperatura_Maxima >= 0)` e integridade referencial com `ON DELETE RESTRICT` para autoclaves.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Ciclo_Esterilizacao`, crie a coluna `Telemetria_Ciclo_Json JSONB` (ex: `{"fase_esterilizacao_minutos": 15, "fase_secagem_minutos": 20, "pressao_media_bar": 2.18, "alarme_temperatura": false}`).
   * Crie o índice GIN `CREATE INDEX idx_cme_telemetria_gin ON Ciclo_Esterilizacao USING GIN (Telemetria_Ciclo_Json);`.
   * Realize consulta utilizando `@>` buscando ciclos onde `"alarme_temperatura": false`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_kits_prontos_arsenal` trazendo kits estéreis disponíveis com contagem de instrumentais e dias até o vencimento.
   * **Materialized View:** `vm_eficiencia_autoclaves_semanal` consolidando taxa de ciclos abortados e volume de kits esterilizados por autoclave, com atualização concorrente via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Crie uma validação que intercepte a tentativa de vincular um kit a uma cirurgia e, caso o ciclo do kit esteja com status diferente de `Aprovado e Liberado` ou o teste biológico seja positivo/em incubação, aborte a transação com `RAISE EXCEPTION 'ERRO DE BIOSSEGURANÇA: Kit não aprovado pelo controle biológico!'`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_liberar_ciclo_esterilizacao(p_ciclo_id INT, p_resultado_biologico VARCHAR)` declarando variáveis com ancoragem `%TYPE`, aprovando o ciclo, atualizando a data de validade de todos os kits contidos no ciclo e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Setor_Destino, Data_Validade ASC)` para distribuição ágil dos materiais estéreis aos arsenais.
   * **Índice Parcial:** `CREATE INDEX idx_ciclos_abortados ON Ciclo_Esterilizacao (ID_Ciclo) WHERE Status_Ciclo LIKE '%Abortado%';`.
   * **Índice Funcional:** `CREATE INDEX idx_kit_codigo_upper ON Kit_Cirurgico (UPPER(Codigo_Kit));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `ROW_NUMBER() OVER (PARTITION BY Autoclave_ID ORDER BY Data_Hora_Ciclo DESC)` o histórico dos últimos 5 ciclos de cada máquina para auditoria preventiva.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Compare o tempo de busca por kits estéreis prontos antes e depois da criação do índice composto.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Ciclo_Esterilizacao` por ano/mês.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * O único kit vascular estéril (`KIT-VASC-01`) é disputado simultaneamente por uma cirurgia de emergência e uma eletiva. Demonstre o uso de `SELECT ... FOR UPDATE` no kit para garantir alocação única.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `ciclos_esterilizacao`):**
   * Projete o documento incorporando a lista de kits cirúrgicos contidos e os testes biológicos. Justifique a modelagem da CME em NoSQL.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "autoclave_id": 1, "data_hora": -1 }` e índice multikey `{ "kits.codigo": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize ciclos onde algum kit cirúrgico pertencia à especialidade "Cirurgia Cardíaca" e a temperatura máxima do ciclo foi >= 134ºC.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `kits`, agrupando com `$group` por tipo de caixa cirúrgica para calcular o volume total de instrumentais reprocessados no mês.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` alterando o status do kit de `Em Quarentena` para `Liberado` no array de kits após aprovação do indicador biológico.
