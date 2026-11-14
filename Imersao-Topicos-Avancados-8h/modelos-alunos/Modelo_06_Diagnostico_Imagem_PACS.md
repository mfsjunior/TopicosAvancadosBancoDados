# Modelo 06: Centro de Diagnóstico por Imagem (PACS/DICOM)

**Domínio:** Radiologia, Tomografia Computadorizada, Ressonância Magnética e Metadados DICOM  
**Complexidade:** Alta (Grandes Volumes de Metadados Não-Estruturados e Agendamento Concorrente de Salas Blindadas)

---

## 📌 1. Cenário de Negócio
O Centro de Diagnóstico por Imagem (CDI) opera equipamentos pesados de alta tecnologia:
* **Modalidades:** Raios-X Digital (CR/DX), Tomografia Computadorizada (CT), Ressonância Magnética (MR), Ultrassonografia (US) e Mamografia (MG).
* Cada exame gera uma série de imagens no padrão internacional **DICOM**, associadas a um identificador universal único de estudo (**Study Instance UID**).
* Exames com contraste iodado exigem tempo de preparo prévio, punção venosa, questionário de função renal (creatinina recente) e tempo de higienização de sala entre pacientes.
* O controle de radiação acumulada (**Dose de Radiação em mGy ou DLP**) é obrigatório por normas de biossegurança da CNEN/ANVISA.

---

## 📄 2. Planilha Bruta de Entrada (`dados_imagem_pacs.csv`)

Abaixo está o extrato exportado do sistema RIS/PACS do hospital (delimitador: ponto e vírgula `;`):

```csv
ID_Exame_Imagem;Data_Hora_Exame;Paciente_CPF;Nome_Paciente;Modalidade;Regiao_Anatomica;Uso_Contraste_Volume_ml;Aparelho_Nome_Serie;Sala_Blindada;Tecnico_Radiologia_Nome;Medico_Radiologista_CRM;Dose_Radiacao_DLP;Study_UID_DICOM;Laudo_Conclusao;Status_Exame
4001;26/10/2023 08:30;987.654.321-11;Lima Barreto;Tomografia (CT);Tórax e Abdome Total;Iodado Não-Iônico 100ml;Tomógrafo Multislice 64 Canais (SN: CT-9988);Sala CT 01;Téc. Carlos Eduardo;CRM 7766-SP (Dr. Walter Salles);450 mGy.cm;1.2.840.113619.2.55.1001;"Pneumopatia intersticial incipiente em lobo inferior direito";Laudado
4002;26/10/2023 09:15;876.543.210-22;Lygia Fagundes Telles;Ressonância (MR);Encéfalo com Difusão;Gadolíneo 15ml;Ressonância Magnética 1.5 Tesla (SN: MR-3322);Sala RM 02;Téc. Marina Silva;CRM 7766-SP (Dr. Walter Salles);0 mGy.cm (Não Ionizante);1.2.840.113619.2.55.1002;"Exame dentro dos padrões da normalidade para a faixa etária";Laudado
4003;26/10/2023 10:00;765.432.109-33;Ariano Suassuna;Raios-X (DX);Tórax PA e Perfil;Nenhum;Aparelho de RX Digital Coluna Móvel (SN: RX-1100);Sala RX 03;Téc. Carlos Eduardo;CRM 8844-SP (Dra. Laís Bodanzky);15 mGy.cm;1.2.840.113619.2.55.1003;"Ausência de derrame pleural ou consolidações";Laudado
4004;26/10/2023 10:45;654.321.098-44;Monteiro Lobato;Tomografia (CT);Crânio sem Contraste;Nenhum;Tomógrafo Multislice 64 Canais (SN: CT-9988);Sala CT 01;Téc. Marina Silva;CRM 8844-SP (Dra. Laís Bodanzky);320 mGy.cm;1.2.840.113619.2.55.1004;NULL;Pendente de Laudo
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente`, `Equipamento_Imagem`, `Sala_Blindada`, `Tecnico_Radiologia`, `Medico_Radiologista`, `Exame_Imagem` e `Laudo_Radiologico`.
   * Chave natural única para o `Study_UID_DICOM` (`UNIQUE NOT NULL`), restrição `CHECK (Dose_Radiacao_DLP >= 0)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Exame_Imagem`, crie a coluna `Tags_DICOM_Json JSONB` (ex: `{"kvp": 120, "ma": 250, "slice_thickness": 1.25, "contrast_bolus": true, "series_count": 4}`).
   * Crie o índice GIN `CREATE INDEX idx_dicom_tags_gin ON Exame_Imagem USING GIN (Tags_DICOM_Json);`.
   * Execute consulta com `@>` buscando exames com `"contrast_bolus": true`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_worklist_radiologia` exibindo fila de exames realizados aguardando laudo com tempo decorrido.
   * **Materialized View:** `vm_dosimetria_paciente_anual` com dose total de radiação ionizante acumulada por paciente no ano, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se o paciente que vai realizar exame de Tomografia com Contraste possui exame de Creatinina registrado nos últimos 30 dias com valor <= 1.5 mg/dL. Caso não possua ou esteja alterada, bloqueie o agendamento via `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_liberar_laudo_imagem(p_exame_id INT, p_radiologista_crm VARCHAR, p_texto_conclusao TEXT)` declarando variáveis com ancoragem `%TYPE`, vinculando o laudo, alterando status para 'Laudado' e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Modalidade, Data_Hora_Exame DESC)` para filtros da estação de trabalho.
   * **Índice Parcial:** `CREATE INDEX idx_exames_pendentes_laudo ON Exame_Imagem (ID_Exame_Imagem) WHERE Status_Exame = 'Pendente de Laudo';`.
   * **Índice Funcional:** `CREATE INDEX idx_regiao_anatomica_upper ON Exame_Imagem (UPPER(Regiao_Anatomica));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `AVG(Dose_Radiacao_DLP) OVER (PARTITION BY Modalidade, Regiao_Anatomica)` a dose média de radiação por região anatômica para auditoria de proteção radiológica.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente a medição de buffer hit comparando a busca da fila de laudos com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Exame_Imagem` por ano/trimestre.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Dois atendentes tentam agendar simultaneamente dois exames com contraste na **Sala CT 01** no mesmo horário. Aplique `SELECT ... FOR UPDATE` na sala para garantir o tempo de higienização obrigatório.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `estudos_radiologicos`):**
   * Projete o documento incorporando os metadados DICOM técnicos e a conclusão do laudo. Justifique a modelagem de imagens diagnósticas em NoSQL.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "modalidade": 1, "data_hora": -1 }` e índice multikey `{ "achados_diagnosticos": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize estudos de tomografia computadorizada onde a espessura de corte foi <= 1.0mm e a dose de radiação superou 300 mGy.cm.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$group` calculando o tempo médio em minutos entre a realização do exame e a emissão do laudo por médico radiologista.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$set` para anexar a URL do visualizador Web DICOM e o status laudado de forma atômica.
