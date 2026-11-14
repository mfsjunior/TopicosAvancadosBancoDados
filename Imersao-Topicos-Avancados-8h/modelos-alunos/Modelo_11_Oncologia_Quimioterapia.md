# Modelo 11: Oncologia, Protocolos Quimioterápicos e Ciclos de Infusão

**Domínio:** Oncologia Clínica, Terapia Antineoplásica e Farmácia de Manipulação Citotóxica  
**Complexidade:** Altíssima (Cálculo Fisiológico de Dose por Área de Superfície Corporal e Validação Hematológica)

---

## 📌 1. Cenário de Negócio
No Centro de Infusão Oncológica, o tratamento quimioterápico segue rigorosos protocolos internacionais (ex: AC-T para mama, FOLFOX para cólon, CHOP para linfoma):
* Cada paciente possui um diagnóstico com estadiamento tumoral (TNM) e dados biométricos atualizados em cada sessão: **Peso (kg)** e **Altura (cm)**.
* A partir do peso e altura, o sistema calcula a **Área de Superfície Corporal (ASC em m²)** pela fórmula de Mosteller:  
  $$\text{ASC} = \sqrt{\frac{\text{Peso (kg)} \times \text{Altura (cm)}}{3600}}$$
* As doses dos medicamentos citotóxicos são calculadas com base na ASC (ex: Doxorrubicina $60 \text{ mg/m}^2$, Ciclofosfamida $600 \text{ mg/m}^2$).
* Antes de liberar a infusão na cabine de fluxo laminar da farmácia oncológica, o médico oncologista deve validar o hemograma recente: **se Plaquetas < 100.000 ou Neutrófilos < 1.500, o ciclo deve ser suspenso por toxicidade medular**.

---

## 📄 2. Planilha Bruta de Entrada (`dados_oncologia_quimioterapia.csv`)

Abaixo está o extrato exportado do sistema de oncologia clínica (delimitador: ponto e vírgula `;`):

```csv
ID_Sessao_Quimio;Data_Hora_Sessao;Paciente_CPF;Nome_Paciente;Peso_Kg;Altura_cm;Superficie_Corporal_m2;Diagnostico_CID_Estadio;Protocolo_Nome;Ciclo_Atual_Total;Drogas_Doses_Calculadas;Plaquetas_Pre_Sessao;Neutrofilos_Pre;Oncologista_CRM;Enfermeiro_Oncologico_COREN;Status_Sessao
5501;31/10/2023 08:00;111.444.777-22;Clementina de Jesus;65.0;160;1.70 m2;Câncer de Mama (CID C50.9, Estádio IIB);Protocolo AC;Ciclo 2 de 4;"Doxorrubicina: 102 mg (60mg/m2), Ciclofosfamida: 1020 mg (600mg/m2)";180000 /uL;2800 /uL;CRM 9922-SP (Dr. Drauzio Varella);COREN 4433-SP (Enf. Alzira);Realizada sem Intercorrências
5502;31/10/2023 09:30;222.555.888-33;Pixinguinha;78.0;175;1.95 m2;Adenocarcinoma de Cólon (CID C18.7, Estádio III);Protocolo FOLFOX-6;Ciclo 4 de 12;"Oxaliplatina: 165.7 mg (85mg/m2), Leucovorina: 780 mg (400mg/m2), 5-Fluorouracil: 780 mg bolus + 4680 mg contínuo 46h";85000 /uL [ABAIXO!];1100 /uL [NEUTROPENIA!];CRM 9922-SP (Dr. Drauzio Varella);COREN 4433-SP (Enf. Alzira);Suspensa por Toxicidade Hematológica
5503;31/10/2023 11:00;333.666.999-44;Cartola;58.0;168;1.64 m2;Linfoma Não-Hodgkin Difuso (CID C83.3);Protocolo R-CHOP;Ciclo 1 de 6;"Rituximabe: 615 mg (375mg/m2), Ciclofosfamida: 1230 mg (750mg/m2), Doxorrubicina: 82 mg (50mg/m2), Vincristina: 2.0 mg (teto)";220000 /uL;3400 /uL;CRM 7733-SP (Dra. Angelita Habr-Gama);COREN 5522-SP (Enf. Zeca);Em Infusão
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente`, `Tratamento_Oncologico`, `Protocolo_Quimio`, `Droga_Antineoplasica`, `Droga_Protocolo` (com dose em mg/m²), `Sessao_Infusao` e `Exame_Pre_Sessao`.
   * Chaves primárias com `SERIAL` ou `UUID`, constraints `CHECK (Peso_Kg > 0)` e `CHECK (Altura_cm > 0)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Sessao_Infusao`, crie a coluna `Toxicidades_Graus_Json JSONB` (ex: `{"grau_nauseas": 1, "grau_fadiga": 2, "mucosite": 0, "neuropatia_periferica": 1}`).
   * Crie o índice GIN `CREATE INDEX idx_toxicidade_gin ON Sessao_Infusao USING GIN (Toxicidades_Graus_Json);`.
   * Realize consulta utilizando `@>` para buscar sessões onde `"neuropatia_periferica": 1`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_agenda_infusao_oncologica` trazendo dados do paciente, protocolo, ciclo atual e status da sessão.
   * **Materialized View:** `vm_dose_acumulada_doxorrubicina` somando a dose vitalícia acumulada por paciente para controle de risco de cardiotoxicidade, atualizada via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide antes da inserção (`BEFORE INSERT`) em `Sessao_Infusao` se o nível de plaquetas é < 100.000 ou neutrófilos < 1.500. Se for, altere compulsoriamente o status para `Suspensa por Toxicidade` e emita `RAISE WARNING` ou `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_prescrever_quimioterapia(p_paciente_id INT, p_protocolo_id INT, p_peso NUMERIC, p_altura INT)` calculando dinamicamente a Superfície Corporal, gerando as doses exatas de cada droga do protocolo com ancoragem `%TYPE` e aplicando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Tratamento_ID, Ciclo_Atual ASC)` para sequência cronológica de infusões.
   * **Índice Parcial:** `CREATE INDEX idx_sessoes_suspensas ON Sessao_Infusao (ID_Sessao) WHERE Status_Sessao LIKE '%Suspensa%';`.
   * **Índice Funcional:** `CREATE INDEX idx_protocolo_nome_upper ON Protocolo_Quimio (UPPER(Nome_Protocolo));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `SUM(Dose_Total_Mg) OVER (PARTITION BY Paciente_ID, Droga_ID ORDER BY Data_Hora_Sessao)` a dose cumulativa total de cada medicamento recebido pelo paciente ao longo do tratamento.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente o plano de execução comparando a busca de sessões suspensas com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Sessao_Infusao` por ano/trimestre.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Dois farmacêuticos oncologistas tentam reservar a única **Cabine de Fluxo Laminar Classe II B2** disponível para manipulação de citostáticos no mesmo horário. Aplique `SELECT ... FOR UPDATE` na cabine para serializar a preparação estéril.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `linhas_cuidado_oncologia`):**
   * Documento BSON rico representando a linha de cuidado completa do paciente com array de `ciclos_realizados`. Justifique a abordagem de manter o histórico de infusões no mesmo documento.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "paciente_cpf": 1, "protocolo": 1 }` e índice multikey `{ "ciclos.drogas.nome": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize tratamentos onde qualquer ciclo de quimioterapia tenha sido suspenso por toxicidade hematológica.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `ciclos`, agrupando com `$group` por protocolo quimioterápico para calcular a taxa de conclusão de ciclos no prazo previsto.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$push` para registrar um novo ciclo de infusão concluído no array do paciente de forma atômica.
