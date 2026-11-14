# Modelo 07: Banco de Sangue, Tipagem Sanguínea e Hemoterapia

**Domínio:** Hematologia, Hemoterapia, Fracionamento de Hemocomponentes e Biossegurança  
**Complexidade:** Alta (Rastreabilidade Estrita Doador-Receptor, Validades Curtas e Concorrência de Reserva)

---

## 📌 1. Cenário de Negócio
O Banco de Sangue hospitalar (Hemocentro) opera sob rigorosas normas da ANVISA e do Ministério da Saúde:
* Um voluntário realiza uma **Doação de Sangue Total** (aproximadamente 450 ml).
* A bolsa passa por **Triagem Sorológica e Imuno-hematológica** obrigatória (HIV, Hepatite B/C, Chagas, Sífilis, HTLV, Tipagem ABO e Fator Rh).
* O sangue total aprovado é fracionado por centrifugação em até 4 hemocomponentes com tempos de vida útil totalmente distintos:
  * **Concentrado de Hemácias (CH):** Validade de 35 a 42 dias (temperatura de 2ºC a 6ºC).
  * **Concentrado de Plaquetas (CP):** Validade crítica de apenas 5 dias (agitação contínua a 22ºC).
  * **Plasma Fresco Congelado (PFC):** Validade de até 1 ano (congelado a -20ºC).
  * **Crioprecipitado (CRIO):** Validade de até 1 ano.
* A transfusão para um paciente receptor exige prova de compatibilidade cruzada direta (*cross-match*) e reserva física imediata no sistema.

---

## 📄 2. Planilha Bruta de Entrada (`dados_banco_sangue.csv`)

Abaixo está o extrato exportado do sistema hemoterápico (delimitador: ponto e vírgula `;`):

```csv
ID_Doacao;Data_Coleta;Doador_CPF;Nome_Doador;Tipo_ABO_Rh;Volume_Coletado_ml;Sorologia_Laudo;Fracionamento_Bolsas_Geradas;Data_Validade_Bolsas;Receptor_Destino_CPF;Nome_Receptor;Status_Bolsa
3001;27/10/2023 08:00;555.666.777-88;Vinicius de Moraes;O Positivo;450 ml;Negativo para todas as sorologias;"CH-3001 (Hemácias, 250ml, Val: 01/12/2023), CP-3001 (Plaquetas, 50ml, Val: 01/11/2023), PFC-3001 (Plasma, 150ml, Val: 27/10/2024)";Disponível no Estoque;NULL;NULL;Liberada no Estoque
3002;27/10/2023 08:30;666.777.888-99;Tom Jobim;O Negativo [Doador Universal];450 ml;Negativo para todas as sorologias;"CH-3002 (Hemácias, 250ml, Val: 01/12/2023), PFC-3002 (Plasma, 200ml, Val: 27/10/2024)";Reservada para Emergência Cirúrgica;111.222.333-44;João Gilberto;Reservada para Cirurgia Cardíaca
3003;27/10/2023 09:15;777.888.999-00;Baden Powell;A Positivo;450 ml;Reagente para Hepatite B (HBsAg Reagente);"Nenhuma (Descarte Obrigatório)";Descartada;NULL;NULL;Descartada por Sorologia Positiva
3004;27/10/2023 09:40;888.999.000-11;Chico Buarque;AB Positivo [Receptor Universal];450 ml;Negativo para todas as sorologias;"CH-3004 (Hemácias, 250ml, Val: 01/12/2023), CP-3004 (Plaquetas, 50ml, Val: 01/11/2023)";Transfundida;999.888.777-66;Edu Lobo;Transfusão Concluída sem Intercorrências
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Doador`, `Doacao_Coleta`, `Triagem_Sorologica`, `Hemocomponente_Bolsa`, `Paciente_Receptor` e `Transfusao`.
   * Restrições `CHECK (Tipo_Sanguineo IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'))` e `CHECK (Volume_ml > 0)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Triagem_Sorologica`, crie `Resultados_Sorologia_Json JSONB` (ex: `{"hiv": "Não Reagente", "hepatite_b": "Não Reagente", "hepatite_c": "Não Reagente", "chagas": "Não Reagente", "sifilis": "Não Reagente", "aprovado": true}`).
   * Crie o índice GIN `CREATE INDEX idx_sorologia_gin ON Triagem_Sorologica USING GIN (Resultados_Sorologia_Json);`.
   * Realize consulta utilizando `@>` para encontrar testes com `"aprovado": false`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_estoque_bolsas_disponiveis` listando bolsas liberadas com dias restantes de validade.
   * **Materialized View:** `vm_inventario_critico_tipo_sanguineo` somando o volume total disponível por tipo sanguíneo, atualizada via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se uma bolsa com status `Descartada` ou `Vencida` está sendo vinculada a uma transfusão, bloqueando a operação com `RAISE EXCEPTION 'ALERTA SANITÁRIO GRAVE: Tentativa de transfundir bolsa inválida ou vencida!'`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_reservar_bolsa_emergencia(p_bolsa_id INT, p_receptor_id INT)` declarando variáveis com ancoragem `%TYPE`, verificando a compatibilidade ABO/Rh e reservando a bolsa com `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Tipo_Sanguineo, Data_Validade ASC)` para saída rápida por ordem de vencimento (FIFO/FEFO).
   * **Índice Parcial:** `CREATE INDEX idx_bolsas_livres ON Hemocomponente_Bolsa (ID_Bolsa) WHERE Status_Bolsa = 'Liberada no Estoque';`.
   * **Índice Funcional:** `CREATE INDEX idx_codigo_bolsa_clean ON Hemocomponente_Bolsa (TRIM(Codigo_Bolsa));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `DENSE_RANK() OVER (PARTITION BY Tipo_Hemocomponente ORDER BY Data_Validade ASC)` a ordem prioritária de dispensação das bolsas de plaquetas e hemácias para evitar descarte por vencimento.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente o plano de execução comparando a busca de bolsas O- com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Doacao_Coleta` por ano/mês com base na `Data_Coleta`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * O hospital possui apenas uma bolsa O-Negativo (`CH-3002`). Dois médicos cirurgiões tentam reservá-la simultaneamente. Demonstre o uso de `SELECT ... FOR UPDATE` para evitar reserva dupla.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `bolsas_sangue`):**
   * Projete o documento da bolsa incorporando os testes sorológicos e a cadeia de custódia (temperaturas). Justifique a escolha de embedding.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "tipo_sanguineo": 1, "data_validade": 1 }` e índice multikey `{ "fracionamento.codigo": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize bolsas onde o hemocomponente fracionado seja "Plaquetas" e a data de validade expire em menos de 48 horas.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$match`, `$group`, `$project` e `$sort` calculando o volume total de sangue em estoque por tipo ABO/Rh.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` alterando o status da bolsa de `Disponível` para `Reservada` com condição atômica no status anterior.
