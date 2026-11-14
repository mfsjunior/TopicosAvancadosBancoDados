# Modelo 02: Bloco Cirúrgico, Equipes Médicas e Procedimentos Anestésicos

**Domínio:** Centro Cirúrgico, Anestesiologia e Escalas de Equipes Multiprofissionais  
**Complexidade:** Alta (Múltiplas Equipes Médicas, Controle de Sala Estéril e Reserva de Equipamentos)

---

## 📌 1. Cenário de Negócio
No Centro Cirúrgico (CC), cada ato operatório é um procedimento complexo que exige a atuação simultânea de múltiplos profissionais:
* **Cirurgião Principal:** Responsável técnico pelo procedimento.
* **Cirurgião Assistente / Auxiliar:** Médico que auxilia no campo operatório.
* **Médico Anestesiologista:** Responsável pelo plano anestésico (Geral, Raquianestesia, Peridural, Sedação) e monitoramento de estabilidade hemodinâmica.
* **Instrumentador Cirúrgico e Circulante de Sala (Enfermagem):** Gerenciam os instrumentais estéreis e a reposição de insumos.

Além dos profissionais, uma cirurgia consome recursos críticos como **Salas Cirúrgicas Estéreis**, **Aparelhos de Anestesia**, **Torres de Vídeo/Laparoscopia** e demanda reserva preventiva de hemocomponentes no Banco de Sangue.

---

## 📄 2. Planilha Bruta de Entrada (`dados_bloco_cirurgico.csv`)

Abaixo está o extrato exportado da central de agendamento cirúrgico (delimitador: ponto e vírgula `;`):

```csv
ID_Cirurgia;Data_Agendamento;Hora_Inicio;Hora_Fim;Paciente_CPF;Nome_Paciente;Cirurgioes_Envolvidos;Anestesistas_Envolvidos;Enfermeiros_Circulantes;Procedimentos_TUSS_Valores;Sala_Cirurgica;Equipamentos_Especiais;Tipo_Anestesia;Medicamentos_Anestesicos_Doses;Reserva_Sangue_ml;Status_Cirurgia
8001;22/10/2023;08:00;12:00;111.333.555-77;Antônio Fagundes;"Dr. Roberto Lima (CRM 1234-SP, Cirurgião Principal), Dr. André Valente (CRM 4321-SP, Auxiliar)";"Dra. Camila Nogueira (CRM 7788-SP)";"Enf. Sandra Pires (COREN 1122), Téc. Mauro Vaz (COREN 3344)";"Apendicectomia Videolaparoscópica (310010): R$ 4500.00, Drenagem de Abscesso (310020): R$ 800.00";Sala 03 - Bloco B;Torre de Vídeo Laparoscópica, Bisturi Elétrico Bipolar;Anestesia Geral;"Propofol 200mg, Fentanil 250mcg, Rocurônio 50mg";0;Realizada
8002;22/10/2023;08:30;10:30;222.444.666-88;Clarice Lispector;"Dr. Marcus Toledo (CRM 9988-SP, Cirurgião Principal)";"Dr. Leonardo Prado (CRM 5566-SP)";"Enf. Sandra Pires (COREN 1122)";"Artroscopia de Joelho (307010): R$ 3800.00";Sala 01 - Bloco A;Torre de Artroscopia, Arco Cirúrgico;Raquianestesia;"Bupivacaína Pesada 15mg, Morfina Subaracnóidea 100mcg";0;Realizada
8003;22/10/2023;13:00;18:00;333.555.777-99;Caetano Veloso;"Dr. Roberto Lima (CRM 1234-SP, Cirurgião Principal), Dra. Patrícia Abravanel (CRM 8811-SP, Auxiliar)";"Dra. Camila Nogueira (CRM 7788-SP)";"Enf. Juliana Ramos (COREN 5566), Téc. Mauro Vaz (COREN 3344)";"Revascularização Miocárdica (309010): R$ 18000.00";Sala 03 - Bloco B;Máquina de Circulação Extracorpórea (CEC), Desfibrilador Interno;Anestesia Geral Balanceada;"Midazolam 15mg, Sufentanil 100mcg, Isoflurano";600 ml Concentrado Hemácias;Em Andamento
8004;22/10/2023;14:00;16:00;444.666.888-00;Elis Regina;"Dr. Marcus Toledo (CRM 9988-SP, Cirurgião Principal)";"Dr. Leonardo Prado (CRM 5566-SP)";"Enf. Sandra Pires (COREN 1122)";"Correção de Fratura de Rádio (307040): R$ 2900.00";Sala 02 - Bloco A;Aparelho de RX Intensificador de Imagem;Bloqueio de Plexo Braquial;"Ropivacaína 0.5% 30ml, Dexmedetomidina 50mcg";0;Cancelada por Falta de Jejum
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas normalizadas: `Paciente`, `Profissional_Saude` (Médicos e Enfermeiros com CRM/COREN e Especialidade), `Sala_Cirurgica`, `Equipamento_Especial`, `Procedimento_Cirurgico`, `Cirurgia`, `Cirurgia_Equipe` (associativa com papel: 'Cirurgião Principal', 'Auxiliar', 'Anestesista', 'Circulante') e `Cirurgia_Procedimento`.
   * Chaves primárias com `SERIAL` ou `UUID`, restrições `CHECK (Hora_Fim > Hora_Inicio)` e `ON DELETE RESTRICT` para profissionais e salas.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Cirurgia`, adicione a coluna `Parametros_Anestesicos_Json JSONB` (ex: `{"tipo_anestesia": "Geral", "drogas": ["Propofol", "Fentanil"], "asa_score": 2, "jejum_horas": 8}`).
   * Crie o índice invertido `CREATE INDEX idx_cirurgia_anestesia_gin ON Cirurgia USING GIN (Parametros_Anestesicos_Json);`.
   * Execute consulta com o operador `@>` buscando cirurgias com `asa_score >= 3` ou tipo "Geral".
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_mapa_cirurgico_diario` com junções trazendo data, sala, cirurgião principal, anestesista e procedimentos.
   * **Materialized View:** `vm_faturamento_equipes_cirurgicas` acumulando total cirúrgico e honorários por cirurgião principal no mês, com índice único e atualização via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se o médico anestesista ou cirurgião principal já possui outra cirurgia marcada no mesmo horário (`Hora_Inicio` a `Hora_Fim`), abortando a transação com `RAISE EXCEPTION 'Conflito de agenda: profissional já alocado em outra sala no mesmo horário!'`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_finalizar_cirurgia(p_cirurgia_id INT, p_hora_fim TIME, p_status VARCHAR)` declarando variáveis com ancoragem `%TYPE`, calculando o tempo cirúrgico real, liberando a sala cirúrgica para limpeza e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Sala_Cirurgica_ID, Data_Agendamento, Hora_Inicio)` para conferência de agenda de salas.
   * **Índice Parcial:** `CREATE INDEX idx_cirurgias_ativas ON Cirurgia (ID_Cirurgia) WHERE Status_Cirurgia = 'Em Andamento';`.
   * **Índice Funcional:** `CREATE INDEX idx_procedimento_nome_upper ON Procedimento_Cirurgico (UPPER(Nome_Procedimento));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com `WITH cirurgias_mes AS (...)` calculando com `ROW_NUMBER() OVER (PARTITION BY Cirurgiao_Principal_ID ORDER BY Valor_Total DESC)` o ranking dos 3 procedimentos mais rentáveis de cada cirurgião.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Avalie a consulta de busca por cirurgiões ativos demonstrando o impacto do índice composto e a redução no custo total do otimizador.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Cirurgia` por ano/trimestre com base na `Data_Agendamento`. Crie as partições e teste o *Partition Pruning*.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Demonstre um cenário de reserva simultânea de uma Sala Cirúrgica e uma Torre de Laparoscopia entre duas equipes médicas rivais, aplicando `FOR UPDATE` para serializar o agendamento e evitar dupla reserva física.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `cirurgias`):**
   * Modele o documento completo da cirurgia **incorporando** a equipe de profissionais e o array de procedimentos faturados. Justifique por que essa abordagem elimina *multi-table joins*.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "data_agendamento": 1, "sala": 1 }` e índice multikey `{ "equipe.crm": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Busque cirurgias onde o médico anestesiologista tenha CRM "7788-SP" e o tipo de anestesia seja "Geral".
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$match`, `$unwind` em `procedimentos`, `$group`, `$project` e `$sort` calculando a receita cirúrgica acumulada e o tempo médio de sala por especialidade cirúrgica.
5. **Atualização Atômica:**
   * Demonstre o uso de `$addToSet` para incluir um novo equipamento especial utilizado no decorrer do ato cirúrgico sem duplicar registros.
