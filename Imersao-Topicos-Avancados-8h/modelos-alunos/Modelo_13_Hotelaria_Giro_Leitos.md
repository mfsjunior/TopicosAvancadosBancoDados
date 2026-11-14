# Modelo 13: Hotelaria Hospitalar, Limpeza Terminal e Giro de Leitos

**Domínio:** Gestão de Leitos (*Bed Management*), Hotelaria Hospitalar, Governança e Higienização  
**Complexidade:** Alta (Máquina de Estados de Leito, Limpeza Especial por Bactéria Multirresistente e Giro Concorrente)

---

## 📌 1. Cenário de Negócio
A central de regulação interna do hospital (*Núcleo Interno de Regulação - NIR*) gerencia a taxa de ocupação e o tempo de giro de leitos (*Turnaround Time*):
* Quando um paciente recebe alta médica, o leito entra imediatamente no estado de **Desocupado - Aguardando Higienização**.
* A equipe de Hotelaria e Governança hospitalar é acionada via rádio/app para realizar o processo de limpeza:
  * **Limpeza Concorrente:** Realizada diariamente enquanto o leito ainda está ocupado pelo mesmo paciente.
  * **Limpeza Terminal Comum:** Desinfecção profunda de teto, paredes, piso, colchão e maçanetas após a alta de paciente sem isolamento.
  * **Limpeza Terminal Especial (Isolamento por Bactéria Multirresistente - KPC, VRE, MRSA):** Exige uso de ácido peracético, nebulização de peróxido de hidrogênio e tempo mínimo de contato com sala fechada.
* Após a limpeza, o leito passa por **Inspeção de Enfermagem/Supervisão** e só então se torna **Disponível para Nova Admissão**.
* Reduzir o tempo ocioso do leito é a principal meta de eficiência do hospital para diminuir as filas do Pronto-Socorro.

---

## 📄 2. Planilha Bruta de Entrada (`dados_hotelaria_leitos.csv`)

Abaixo está o extrato exportado do sistema de controle de leitos (delimitador: ponto e vírgula `;`):

```csv
ID_Giro_Leito;Data_Alta;Leito_Codigo;Andar_Ala_Setor;Tipo_Acomodacao;Paciente_Anterior_Nome;Motivo_Alta;Tipo_Limpeza_Exigida;Camareira_Responsavel_Matricula;Hora_Chamado_Limpeza;Hora_Termino_Limpeza;Tempo_Limpeza_Minutos;Supervisora_Enfermagem_Liberacao;Proximo_Paciente_Aguardando;Status_Leito
8501;02/11/2023;Leito 204;2º Andar - Ala Sul;Apartamento Individual;Heitor Villa-Lobos;Alta Curada;Limpeza Terminal Comum;MAT-101 (Maria da Penha);02/11/2023 10:15;02/11/2023 11:00;45 min;COREN 1122 (Enf. Sandra);Ernesto Nazareth (Aguardando no PS);Liberado para Internação
8502;02/11/2023;Leito 310;3º Andar - Ala Norte;Enfermaria 2 Leitos;Chiquinha Gonzaga;Transferência para UTI;Limpeza Terminal Especial (Isolamento de Contato - KPC);MAT-102 (Antônia Ramos);02/11/2023 10:30;02/11/2023 12:15;105 min;COREN 1122 (Enf. Sandra);Nenhum (Em Quarentena Preventiva);Em Higienização Especial
8503;02/11/2023;Leito 401;4º Andar - Bloco Oncológico;Apartamento Pressão Negativa;Pixinguinha;Alta Médica com Retorno;Limpeza Terminal Especial (Quimioterapia);MAT-101 (Maria da Penha);02/11/2023 11:00;02/11/2023 12:20;80 min;COREN 3344 (Enf. Teresa);Custódio Mesquita;Aguardando Inspeção Final
8504;02/11/2023;Leito 105;1º Andar - Maternidade;Alojamento Conjunto;Carolina Maria de Jesus;Alta com Recém-Nascido;Limpeza Terminal Comum;MAT-103 (Francisca Souza);02/11/2023 11:30;NULL;Em Andamento;NULL;Dona Ivone Lara;Em Higienização
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Ala_Hospitalar`, `Leito`, `Camareira_Hotelaria`, `Supervisor_Enfermagem`, `Protocolo_Limpeza`, `Evento_Giro_Leito` e `Fila_Espera_Internacao`.
   * Restrições `CHECK (Tempo_Limpeza_Minutos >= 0)` e `ON DELETE RESTRICT` para leitos físicos.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Evento_Giro_Leito`, crie a coluna `Checklist_Higienizacao_Json JSONB` (ex: `{"troca_colchao": true, "desinfeccao_macanetas": true, "nebulizacao_h2o2": true, "quarentena_horas": 2}`).
   * Crie o índice GIN `CREATE INDEX idx_checklist_gin ON Evento_Giro_Leito USING GIN (Checklist_Higienizacao_Json);`.
   * Realize consulta utilizando `@>` para buscar leitos que passaram por nebulização (`"nebulizacao_h2o2": true`).
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_painel_giro_leitos_tempo_real` com status do leito, tempo em limpeza e próximo paciente aguardando.
   * **Materialized View:** `vm_turnaround_time_mensal` com tempo médio de giro e horas ociosas por andar, atualizada via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide a máquina de estados do leito: impeça que um leito com status diferente de `Liberado para Internação` seja vinculado a uma nova internação, abortando com `RAISE EXCEPTION 'LEITO NÃO LIBERADO: O leito % ainda está em processo de higienização/inspeção!', NEW.Leito_Codigo`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_aprovar_inspecao_leito(p_evento_giro_id INT, p_supervisor_coren VARCHAR)` declarando variáveis com ancoragem `%TYPE`, alterando o status do leito para `Liberado para Internação`, gravando o carimbo de data/hora e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Ala_ID, Status_Leito)` para painel de leitos disponíveis por setor.
   * **Índice Parcial:** `CREATE INDEX idx_leitos_higienizacao ON Leito (ID_Leito) WHERE Status_Leito LIKE '%Higienização%';`.
   * **Índice Funcional:** `CREATE INDEX idx_leito_codigo_upper ON Leito (UPPER(Codigo_Leito));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `DENSE_RANK() OVER (PARTITION BY Tipo_Acomodacao ORDER BY Data_Alta DESC)` o tempo ocioso de cada leito desocupado para priorização da equipe de limpeza.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Compare o plano de busca de leitos liberados com e sem o índice composto.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Evento_Giro_Leito` por ano/mês.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * A regulação do Pronto-Socorro e a regulação cirúrgica tentam internar dois pacientes no recém-liberado **Leito 204**. Aplique `SELECT ... FOR UPDATE` no leito para evitar overbooking de internação.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `leitos_hospitalares`):**
   * Projete o documento do leito com o estado atual e **incorpore** as últimas 5 higienizações (padrão *Subset Pattern*). Justifique a escolha de limitar o histórico incorporado para não estourar o limite de 16MB.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "andar": 1, "status": 1 }` e índice multikey `{ "historico_limpezas.tipo": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize leitos onde alguma higienização recente do tipo "Limpeza Terminal Especial" levou mais de 90 minutos.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$group` calculando o tempo médio de limpeza (*Turnaround Time*) por camareira e por tipo de protocolo de desinfecção.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` alterando o status do leito de `Em Higienização` para `Liberado` de forma atômica.
