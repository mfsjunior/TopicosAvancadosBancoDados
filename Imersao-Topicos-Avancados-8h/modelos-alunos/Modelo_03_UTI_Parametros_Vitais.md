# Modelo 03: UTI, Monitoramento de Leitos e Parâmetros Vitais Contínuos

**Domínio:** Terapia Intensiva (UTI), Telemetria de Sensores e Ingestão de Séries Temporais  
**Complexidade:** Altíssima (Ingestão Rápida, Séries Temporais de Alta Frequência e Ocupação Crítica de Leitos)

---

## 📌 1. Cenário de Negócio
Na Unidade de Terapia Intensiva (UTI), cada leito abriga um paciente crítico monitorado 24 horas por dia por equipamentos eletrônicos contínuos:
* **Monitores Multiparamétricos:** Registram Pressão Arterial Invasiva (PAI), Frequência Cardíaca (FC), Saturação de Oxigênio (SatO2), Frequência Respiratória (FR) e Temperatura a cada minuto.
* **Ventiladores Mecânicos:** Informam fração inspirada de oxigênio (FiO2), volume corrente e pressão de pico.
* **Bombas de Infusão:** Controlam a vazão (ml/h) de drogas vasoativas de suporte à vida (Noradrenalina, Vasopressina, Fentanil).

Além dos dados dos sensores, médicos intensivistas realizam rondas diárias calculando escores de gravidade clínica (como o **SOFA - Sequential Organ Failure Assessment**) para determinar o risco de mortalidade e guiar o plano terapêutico.

---

## 📄 2. Planilha Bruta de Entrada (`dados_monitoramento_uti.csv`)

Abaixo está o extrato exportado do sistema de telemetria da UTI Adulto (delimitador: ponto e vírgula `;`):

```csv
ID_Medicao_UTI;Timestamp_Leitura;Leito_Numero;Paciente_CPF;Nome_Paciente;Sinais_Vitais_PA_FC_Sat_Temp;Ventilacao_Mecanica_Modo_FiO2;Drogas_Vasoativas_Doses_Bomba;Medico_Intensivista_CRM;Nome_Intensivista;Enfermeiro_Plantao_COREN;Alarmes_Disparados_Sensor;Score_SOFA_Dia;Status_Leito
9001;23/10/2023 10:00:00;Leito 01;123.456.789-01;Manuel Bandeira;PA: 110/70 mmHg, FC: 84 bpm, SatO2: 95%, Temp: 37.1C;Modo VCV, FiO2: 40%, Peep: 8 cmH2O;Noradrenalina: 0.15 mcg/kg/min, Fentanil: 2 ml/h;10203-SP;Dr. Cláudio Fontes;77112-SP;Nenhum;4;Ocupado - Estável
9002;23/10/2023 10:00:00;Leito 02;234.567.890-12;Cecília Meireles;PA: 75/40 mmHg, FC: 138 bpm, SatO2: 86%, Temp: 39.2C;Modo PCV, FiO2: 80%, Peep: 14 cmH2O;Noradrenalina: 0.80 mcg/kg/min, Vasopressina: 0.04 UI/min, Sedação Contínua;10203-SP;Dr. Cláudio Fontes;77112-SP;Alarme: Hipotensão Severa, Dessaturação Aguda;11;Ocupado - Crítico Grave
9003;23/10/2023 10:01:00;Leito 03;345.678.901-23;Guimarães Rosa;PA: 125/80 mmHg, FC: 68 bpm, SatO2: 98%, Temp: 36.5C;Ar Ambiente (Cateter Nasal 2L/min);Nenhuma;20304-SP;Dra. Simone Rezende;88223-SP;Nenhum;1;Ocupado - Em Desmame
9004;23/10/2023 10:01:00;Leito 04;NULL;Vago;NULL;NULL;NULL;20304-SP;Dra. Simone Rezende;88223-SP;Nenhum;0;Disponível - Limpo
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente`, `Leito_UTI`, `Internacao_UTI`, `Profissional_Intensivista`, `Medicao_Sensor_UTI`, `Bomba_Infusao_Dose` e `Escore_SOFA_Diario`.
   * Chaves primárias com `BIGSERIAL` para tabelas de alta frequência de leitura e constraints `CHECK (Score_SOFA BETWEEN 0 AND 24)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Medicao_Sensor_UTI`, armazene a telemetria do ventilador mecânico em `Parametros_Ventilador_Json JSONB` (ex: `{"modo": "PCV", "fio2": 80, "peep": 14, "vol_corrente": 420}`).
   * Crie o índice GIN `CREATE INDEX idx_ventilador_gin ON Medicao_Sensor_UTI USING GIN (Parametros_Ventilador_Json);`.
   * Realize consulta utilizando `@>` para encontrar pacientes com `fio2 > 60` (alto suporte de oxigênio).
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_painel_hemodinamico_leitos` com o último registro de sinais vitais de cada leito ocupado em tempo real.
   * **Materialized View:** `vm_resumo_sofa_semanal` com média de escores de gravidade e mortalidade estimada por leito, atualizada concorrentemente com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Crie uma validação que intercepte a gravação de medições (`BEFORE INSERT`) e, caso a pressão sistólica seja < 80 mmHg e a SatO2 < 88%, insira automaticamente um registro em uma tabela de `Alarme_Critico_UTI` e envie alerta sonoro.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_admitir_paciente_uti(p_paciente_id INT, p_leito_id INT, p_medico_crm VARCHAR)` que valide se o leito está com status 'Disponível', altere o leito para 'Ocupado', crie o registro de internação e execute `COMMIT` atômico.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Leito_ID, Timestamp_Leitura DESC)` para acelerar gráficos de tendência temporal de monitores.
   * **Índice Parcial:** `CREATE INDEX idx_pacientes_graves ON Escore_SOFA_Diario (Internacao_ID) WHERE Score_SOFA >= 8;`.
   * **Índice Funcional:** `CREATE INDEX idx_medicao_data_trunc ON Medicao_Sensor_UTI (DATE_TRUNC('hour', Timestamp_Leitura));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma consulta com CTE calculando com `AVG(SatO2) OVER (PARTITION BY Leito_ID ORDER BY Timestamp_Leitura ROWS BETWEEN 5 PRECEDING AND CURRENT ROW)` a média móvel dos últimos 5 minutos de saturação de oxigênio para suavizar ruídos de leitura de sensores.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Compare o tempo de busca da última hora de telemetria antes e depois da criação do índice composto em `(Leito_ID, Timestamp_Leitura DESC)`.
8. **Particionamento Declarativo por Intervalo (`PARTITION BY RANGE`):**
   * Particione a tabela `Medicao_Sensor_UTI` por dia ou semana usando `PARTITION BY RANGE (Timestamp_Leitura)`. Crie partições diárias e comprove a eficácia do *Partition Pruning*.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Dois médicos intensivistas tentam alocar dois pacientes em estado de choque simultaneamente no único leito vago da UTI (**Leito 04**). Aplique `SELECT ... FOR UPDATE` no registro do leito para serializar a transferência.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Bucket Pattern para Time-Series):**
   * Projete a collection `telemetria_uti` utilizando o padrão **Bucket**: 1 documento por leito por hora, contendo um array `medicoes: [ { minuto: 0, pa: "110/70", fc: 84 }, ... ]`. Justifique por que essa modelagem reduz o tamanho dos índices e a sobrecarga de armazenamento BSON.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "leito_numero": 1, "data_hora_bucket": -1 }` e índice multikey `{ "alarmes.tipo": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize os baldes de medição onde algum minuto registrou saturação de O2 menor que 90% acompanhada de frequência cardíaca > 120 bpm.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `medicoes`, agrupando com `$group` por leito para calcular a pressão arterial média (PAM) mínima e o número total de alarmes críticos disparados.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` utilizando `$push` com o modificador `$each` para adicionar um lote de 5 novas medições ao array do bucket horário do leito.
