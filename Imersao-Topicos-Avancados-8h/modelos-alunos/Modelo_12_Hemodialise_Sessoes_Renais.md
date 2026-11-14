# Modelo 12: Hemodiálise, Máquinas Renais e Reúso de Capilares

**Domínio:** Nefrologia, Terapia Renal Substitutiva (TRS), Osmose Reversa e Biossegurança RDC 11/2014  
**Complexidade:** Alta (Controle Estrito de Reúso de Filtros Capilares e Balanço Hídrico Concorrente)

---

## 📌 1. Cenário de Negócio
No Centro de Diálise do hospital, pacientes com Insuficiência Renal Crônica (IRC) dependem de sessões periódicas de hemodiálise (geralmente 3 vezes por semana, com 4 horas de duração cada):
* Cada paciente possui um **Acesso Vascular Específico** (Fístula Arteriovenosa - FAV ou Cateter de Duplo Lúmen de Longa Permanência - Permcath).
* As sessões ocorrem em **Máquinas de Hemodiálise** conectadas a um sistema de osmose reversa de tratamento de água.
* **Norma da RDC nº 11/2014 da ANVISA para Reúso de Capilares (Dialisadores):** O filtro capilar pode ser reutilizado para o mesmo paciente por no máximo **20 vezes**, desde que o volume de *priming* (capacidade residual de fibras) seja superior a 80% do original e o teste de integridade seja aprovado. Ao atingir o 20º uso, o descarte é obrigatório por lei.
* Antes e depois de cada sessão, o paciente é pesado para calcular o ganho de peso interdialítico e programar a **Taxa de Ultrafiltração (Volume de Líquido a ser Retirado em ml)**.

---

## 📄 2. Planilha Bruta de Entrada (`dados_hemodialise_sessoes.csv`)

Abaixo está o extrato exportado do sistema de diálise hospitalar (delimitador: ponto e vírgula `;`):

```csv
ID_Sessao_Dialise;Data_Sessao;Turno_Horario;Paciente_CPF;Nome_Paciente;Acesso_Vascular_Tipo_Local;Maquina_ID_Poltrona;Filtro_Capilar_Codigo_Reuso;Peso_Seco_Alvo_kg;Peso_Pre_Sessao_kg;Peso_Pos_Sessao_kg;Volume_Ultrafiltrado_ml;Nefrologista_CRM;Intercorrencias_Clinicas;Status_Sessao
6501;01/11/2023;Manhã (07:00-11:00);111.777.333-55;Noel Rosa;Fístula Arteriovenosa (Braço Esquerdo);Máquina Renal 01 (Poltrona 05);CAP-NOEL-01 (Uso 14 de 20, Priming: 88%);68.0;71.5;68.2;3300 ml;CRM 1010-SP (Dr. Adib Jatene);Nenhuma;Concluída com Sucesso
6502;01/11/2023;Manhã (07:00-11:00);222.888.444-66;Nelson Cavaquinho;Cateter Permcath Jugular Direita;Máquina Renal 02 (Poltrona 08);CAP-NELSON-02 (Uso 19 de 20, Priming: 82%);74.0;78.0;74.5;3500 ml;CRM 1010-SP (Dr. Adib Jatene);Queda de Pressão (PA: 80/50 mmHg), Infusão de 100ml SF 0.9%;Concluída com Intercorrência
6503;01/11/2023;Tarde (12:00-16:00);333.999.555-77;Ismael Silva;Fístula Arteriovenosa (Braço Direito);Máquina Renal 01 (Poltrona 05);CAP-ISMAEL-03 (Uso 20 de 20 [LIMITE ATINGIDO!]);80.0;83.2;80.1;3100 ml;CRM 2020-SP (Dra. Zilda Arns);Nenhuma;Concluída - Filtro Encaminhado para Descarte
6504;01/11/2023;Tarde (12:00-16:00);444.000.666-88;Moreira da Silva;Fístula Arteriovenosa (Braço Esquerdo);Máquina Renal 03 (Poltrona 02);CAP-MOREIRA-04 (Uso 21 de 20 [VIOLAÇÃO ANVISA!]);70.0;73.0;NULL;0 ml;CRM 2020-SP (Dra. Zilda Arns);Tentativa de início bloqueada pelo sistema;Sessão Bloqueada por Filtro Vencido
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente_Renal`, `Acesso_Vascular`, `Maquina_Hemodialise`, `Filtro_Capilar`, `Sessao_Dialise` e `Intercorrencia_Sessao`.
   * Restrições `CHECK (Numero_Reuso_Atual <= 20)` e `CHECK (Volume_Ultrafiltrado_ml >= 0)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Sessao_Dialise`, crie `Parametros_Dialise_Json JSONB` (ex: `{"fluxo_sangue_qb": 350, "fluxo_dialisato_qd": 500, "condutividade": 13.8, "temperatura_banho": 36.5}`).
   * Crie o índice GIN `CREATE INDEX idx_dialise_parametros_gin ON Sessao_Dialise USING GIN (Parametros_Dialise_Json);`.
   * Realize consulta utilizando `@>` para buscar sessões com `"fluxo_sangue_qb": 350`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_mapa_poltronas_turno_ativo` exibindo pacientes e máquinas alocadas no turno atual.
   * **Materialized View:** `vm_reuso_capilares_status` com número de reúsos restantes de cada filtro capilar e taxa de priming residual, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se o filtro capilar associado à sessão possui `Numero_Reuso_Atual >= 20`. Se possuir, bloqueie o início da sessão com `RAISE EXCEPTION 'VIOLAÇÃO RDC 11/2014: Filtro capilar atingiu o limite de 20 usos e deve ser descartado!'`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_finalizar_sessao_dialise(p_sessao_id INT, p_peso_pos NUMERIC)` declarando variáveis com ancoragem `%TYPE`, calculando o balanço hídrico final, incrementando o contador de reúso do capilar e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Maquina_ID, Turno, Data_Sessao)` para agenda das poltronas de diálise.
   * **Índice Parcial:** `CREATE INDEX idx_filtros_pre_descarte ON Filtro_Capilar (ID_Filtro) WHERE Numero_Reuso_Atual >= 18;`.
   * **Índice Funcional:** `CREATE INDEX idx_paciente_cpf_num ON Paciente_Renal (CAST(REGEXP_REPLACE(CPF, '[^0-9]', '', 'g') AS BIGINT));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `AVG(Volume_Ultrafiltrado_ml) OVER (PARTITION BY Paciente_ID ORDER BY Data_Sessao ROWS BETWEEN 3 PRECEDING AND CURRENT ROW)` a média móvel de perda de peso/líquido nas últimas 3 sessões do paciente.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente a medição do plano de busca de filtros próximos ao descarte com o índice parcial ativo.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Sessao_Dialise` por ano/mês com base na `Data_Sessao`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Dois pacientes crônicos solicitam a mesma poltrona e máquina no turno da Manhã. Aplique `SELECT ... FOR UPDATE` no slot de máquina/turno para serializar a marcação e impedir conflito físico.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `sessoes_dialise`):**
   * Documento BSON incorporando as aferições de pressão horárias da sessão de 4h e intercorrências. Justifique a modelagem de balanço hídrico em NoSQL.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "maquina_id": 1, "data_sessao": -1 }` e índice multikey `{ "intercorrencias.descricao": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize sessões onde houve intercorrência com conduta médica de "Infusão de SF 0.9%" ou onde o volume ultrafiltrado superou 3200 ml.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$group` calculando a perda de peso média em kg e o percentual de sessões com intercorrências por turno.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$inc: { "numero_reuso": 1 }` na collection de dialisadores para incremento atômico de lavagem.
