# Modelo 10: Maternidade, Berçário e Prontuário Neonatal

**Domínio:** Obstetrícia, Neonatologia, Segurança Materno-Infantil e Gemelaridade  
**Complexidade:** Alta (Relações 1:N Dinâmicas Mãe-Bebês em Partos Gemelares e Vínculo Biométrico de Pulseiras)

---

## 📌 1. Cenário de Negócio
No Centro Obstétrico e Berçário Neonatal, o nascimento é um evento que liga simultaneamente duas vidas:
* A **Parturiente (Mãe)** é admitida em trabalho de parto.
* O parto (Normal ou Cesárea) é realizado por uma equipe composta por Obstetra, Médico Pediatra/Neonatologista e Enfermeira Obstétrica.
* Um parto pode gerar **um ou mais recém-nascidos** (gestação única, gemelar, trigemelar - relação 1:N).
* No momento exato do nascimento (minuto de ouro), o neonatologista avalia a vitalidade do bebê através da **Escala de Apgar** no 1º e 5º minuto (frequência cardíaca, esforço respiratório, tônus muscular, irritabilidade reflexa e cor).
* Para segurança absoluta contra trocas, mãe e bebê(s) recebem **Pulseiras com Códigos Alfanuméricos Idênticos e Lacres Invioláveis**, além de coleta de sangue de cordão umbilical para tipagem e teste de Coombs.
* Mãe e bebê estáveis seguem para o **Alojamento Conjunto (Leito Mãe-Bebê)**; se o bebê tiver Apgar baixo ou prematuridade, ele é encaminhado para a **UTI Neonatal (Incubadora)**.

---

## 📄 2. Planilha Bruta de Entrada (`dados_maternidade_partos.csv`)

Abaixo está o extrato exportado da sala de parto e berçário (delimitador: ponto e vírgula `;`):

```csv
ID_Parto;Data_Hora_Nascimento;Mae_CPF;Nome_Mae;Tipo_Parto;Obstetra_CRM;Pediatra_Neonatologista_CRM;Enfermeira_Obstetra_COREN;Recem_Nascidos_Dados_Pulseiras;Alojamento_Conjunto_Leito;Status_Pos_Parto
9501;30/10/2023 04:15;111.999.888-77;Carolina Maria de Jesus;Parto Normal Humanizado;CRM 3322-SP (Dr. Raul Seixas);CRM 4411-SP (Dra. Rita Lee);COREN 9988-SP (Enf. Nara Leão);"RN 01 (Sexo: M, Peso: 3250g, Comp: 49cm, Apgar1: 9, Apgar5: 10, Pulseira: PULS-9501-A, Tipagem: A+)";Quarto 102 - Alojamento Conjunto;Mãe e Bebê em Aleitamento Materno Exclusivo
9502;30/10/2023 06:40;222.888.777-66;Chiquinha Gonzaga;Cesárea de Emergência;CRM 5544-SP (Dr. Tim Maia);CRM 4411-SP (Dra. Rita Lee);COREN 7766-SP (Enf. Gal Costa);"RN 01 - Gêmeo A (Sexo: F, Peso: 1950g, Comp: 42cm, Apgar1: 6, Apgar5: 8, Pulseira: PULS-9502-A, Tipagem: O+), RN 02 - Gêmeo B (Sexo: F, Peso: 1820g, Comp: 41cm, Apgar1: 5, Apgar5: 7, Pulseira: PULS-9502-B, Tipagem: O+)";Mãe: Leito 105 / Bebês: Incubadoras 03 e 04 (UTI Neonatal);Bebês Prematuros em Monitorização Contínua
9503;30/10/2023 08:20;333.777.666-55;Dona Ivone Lara;Parto Normal;CRM 3322-SP (Dr. Raul Seixas);CRM 6655-SP (Dr. Jorge Ben);COREN 9988-SP (Enf. Nara Leão);"RN 01 (Sexo: F, Peso: 3400g, Comp: 50cm, Apgar1: 8, Apgar5: 9, Pulseira: PULS-9503-A, Tipagem: B+)";Quarto 103 - Alojamento Conjunto;Mãe e Bebê Estáveis
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Parturiente_Mae`, `Equipe_Obstetrica`, `Evento_Parto`, `Recem_Nascido` e `Leito_Alojamento_Conjunto`.
   * Chave primária com `SERIAL` ou `UUID`, `UNIQUE` no código da pulseira do bebê, e restrições `CHECK (Apgar_1min BETWEEN 0 AND 10)` e `CHECK (Peso_Gramas > 0)`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Recem_Nascido`, crie a coluna `Dados_Biometricos_Cordao_Json JSONB` (ex: `{"coombs_direto": "Negativo", "gasometria_cordao_ph": 7.32, "clampeamento_tardio": true, "amamentacao_primeira_hora": true}`).
   * Crie o índice GIN `CREATE INDEX idx_rn_biometria_gin ON Recem_Nascido USING GIN (Dados_Biometricos_Cordao_Json);`.
   * Realize consulta utilizando `@>` para localizar recém-nascidos que amamentaram na primeira hora de vida (`"amamentacao_primeira_hora": true`).
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_censo_bercario_ativo` com dados da mãe, bebê, número do leito e status pós-parto.
   * **Materialized View:** `vm_indicadores_parto_obstetra` acumulando taxa de partos normais vs cesáreas por médico no ano, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se o código de pulseira do recém-nascido segue rigorosamente o padrão `PULS-XXXX-X` e, caso o Apgar no 5º minuto seja < 7, obrigue o encaminhamento para a UTI Neonatal via `NEW.Destino = 'UTI Neonatal'`, lançando aviso ou abortando inconsistências com `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_registrar_alta_mae_bebe(p_parto_id INT)` declarando variáveis com ancoragem `%TYPE`, liberando o leito de alojamento conjunto, registrando a data de alta e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Mae_ID, Data_Hora_Nascimento DESC)` para histórico obstétrico da mãe.
   * **Índice Parcial:** `CREATE INDEX idx_bebes_baixo_peso ON Recem_Nascido (ID_Recem_Nascido) WHERE Peso_Gramas < 2500;`.
   * **Índice Funcional:** `CREATE INDEX idx_mae_cpf_clean ON Parturiente_Mae (REGEXP_REPLACE(CPF, '[^0-9]', '', 'g'));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `PERCENT_RANK() OVER (PARTITION BY Sexo ORDER BY Peso_Gramas)` o percentil de peso de cada bebê por gênero para curvas de crescimento da OMS.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente a medição do plano de busca de recém-nascidos de baixo peso com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Evento_Parto` por ano/mês com base na `Data_Hora_Nascimento`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Duas puérperas com bebês recém-nascidos disputam o último quarto com leito de Alojamento Conjunto disponível. Demonstre o uso de `SELECT ... FOR UPDATE` para evitar alocação dupla.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `prontuarios_parto`):**
   * Documento BSON rico representando o parto e **incorporando** o array de recém-nascidos (`recem_nascidos: [ { ... } ]`). Justifique a facilidade de representar partos gemelares em documentos.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "tipo_parto": 1, "data_nascimento": -1 }` e índice multikey `{ "recem_nascidos.pulseira": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize nascimentos onde qualquer bebê do parto teve Apgar de 1º minuto menor que 7 ou peso inferior a 2000g.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `recem_nascidos`, agrupando com `$group` por tipo de parto para calcular o peso médio dos bebês e o percentual de partos gemelares.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` utilizando `$push` para adicionar anotações de enfermagem no array de evolução do alojamento conjunto.
