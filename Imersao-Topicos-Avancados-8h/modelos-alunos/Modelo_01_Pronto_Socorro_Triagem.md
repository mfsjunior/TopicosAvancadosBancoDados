# Modelo 01: Pronto-Socorro, Triagem Manchester e Classificação de Risco

**Domínio:** Emergência Hospitalar, Triagem Manchester e Alocação Concorrente de Leitos  
**Complexidade:** Alta (Fluxo Contínuo, Priorização por Cores e Ingestão Transacional Rápida)

---

## 📌 1. Cenário de Negócio
No Pronto-Socorro de alta complexidade, cada paciente que chega passa imediatamente por uma **Triagem pelo Protocolo de Manchester**. O enfermeiro avaliador afere múltiplos sinais vitais simultâneos e define uma cor de prioridade que estabelece o tempo máximo tolerável de espera:
* **Vermelho (Emergência):** Atendimento imediato (0 min).
* **Laranja (Muito Urgente):** Até 10 minutos.
* **Amarelo (Urgente):** Até 50 minutos.
* **Verde (Pouco Urgente):** Até 120 minutos.
* **Azul (Não Urgente):** Até 240 minutos.

Após a triagem, o paciente é direcionado para um **Box de Atendimento** (ex: Box Vermelho de Ressuscitação, Box Amarelo Clínico) ou Poltrona de Medicação Rápida. Médicos plantonistas assumem os casos de acordo com a gravidade, podendo solicitar exames laboratoriais rápidos (POCT - *Point of Care Testing*) e prescrever analgesia venosa imediata.

---

## 📄 2. Planilha Bruta de Entrada (`dados_pronto_socorro.csv`)

Abaixo está o extrato real gerado pelo sistema legado da recepção do PS (delimitador: ponto e vírgula `;`):

```csv
ID_Atendimento_PS;Data_Hora_Chegada;Paciente_CPF;Paciente_Nome;Sinais_Vitais_Aferidos;Queixas_Principais;Protocolo_Cor;Tempo_Max_Minutos;Enfermeiro_Triagem_COREN;Nome_Enfermeiro;Medico_Plantao_CRM;Nome_Medico;Especialidades_Medico;Box_Designado;Equipamentos_Box;Conduta_Medicamentos_Iniciais;Status_Atendimento
5001;20/10/2023 07:15;101.202.303-44;Carlos Drumond;PA: 190/110 mmHg, FC: 115 bpm, SatO2: 91%, Temp: 36.8C;Dor torácica súbita, dispneia intensa;Vermelho;0;123456-SP;Enf. Roberta Maia;88771;SP;Dr. Paulo Ventura;Cardiologia, Terapia Intensiva;Box Vermelho 01;Monitor Multiparamétrico, Desfibrilador, Aspirador Central;"Morfina 2mg IV, Nitroglicerina 5mcg/min";Em Atendimento
5002;20/10/2023 07:20;202.303.404-55;Beatriz Lins;PA: 120/80 mmHg, FC: 78 bpm, SatO2: 98%, Temp: 38.9C;Febre alta há 3 dias, mialgia, cefaleia;Amarelo;50;654321-SP;Enf. Juliana Teles;99112;SP;Dra. Fernanda Braga;Clínica Médica;Box Amarelo 04;Termômetro Digital, Esfigmomanômetro;"Dipirona 1g EV diluída";Aguardando Reavaliação
5003;20/10/2023 07:35;303.404.505-66;Marcos Vinicius;PA: 130/85 mmHg, FC: 82 bpm, SatO2: 97%, Temp: 36.5C;Entorse em tornozelo direito pós-futebol;Verde;120;123456-SP;Enf. Roberta Maia;55443;SP;Dr. Thiago Leite;Ortopedia, Traumatologia;Box Ortopedia 02;Aparelho de Imobilização, Fita Métrica;"Cetoprofeno 100mg IM, Gelo local";Liberado com Encaminhamento
5004;20/10/2023 07:40;404.505.606-77;Helena Prado;PA: 80/50 mmHg, FC: 130 bpm, SatO2: 88%, Temp: 39.4C;Rebaixamento de consciência, confusão mental pós-infecciosa;Laranja;10;654321-SP;Enf. Juliana Teles;88771;SP;Dr. Paulo Ventura;Cardiologia, Terapia Intensiva;Box Vermelho 02;Respirador Mecânico, Bomba de Infusão 03 Canais;"Ceftriaxona 2g EV, Solução Fisiológica 1000ml em bolus";Internação em UTI Solicitada
5005;20/10/2023 08:00;505.606.707-88;Rogério Duarte;PA: 125/80 mmHg, FC: 72 bpm, SatO2: 99%, Temp: 36.6C;Renovação de receita médica de hipertensão de uso contínuo;Azul;240;123456-SP;Enf. Roberta Maia;99112;SP;Dra. Fernanda Braga;Clínica Médica;Consultório Rápido 01;Estetoscópio;"Nenhum";Liberado com Receita
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo:**
   * Desmembrar a planilha em tabelas na **3ª Forma Normal**: `Paciente`, `Enfermeiro_Triagem`, `Medico_Plantao`, `Protocolo_Manchester`, `Box_Emergencia`, `Atendimento_PS` e `Prescricao_Emergencia`.
   * Integridade referencial com `ON DELETE CASCADE` para prescrições e `ON DELETE RESTRICT` para médicos e leitos. Constraints `CHECK (Protocolo_Cor IN ('Vermelho', 'Laranja', 'Amarelo', 'Verde', 'Azul'))`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela de triagem, crie a coluna `Sinais_Vitais_Json JSONB` (ex: `{"pa_sistolica": 190, "pa_diastolica": 110, "fc": 115, "sato2": 91, "temp": 36.8}`).
   * Crie um índice `CREATE INDEX idx_triagem_sinais_gin ON Triagem USING GIN (Sinais_Vitais_Json);`.
   * Realize uma busca usando o operador de contenção `@>` buscando pacientes febris (`temp > 38.0`).
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_painel_espera_ps` com `JOIN` entre paciente, triagem e médico, exibindo tempo decorrido desde a chegada.
   * **Materialized View:** `vm_estatisticas_manchester_diaria` com total de atendimentos por cor e tempo médio de espera. Crie índice único nela e demonstre `REFRESH MATERIALIZED VIEW CONCURRENTLY vm_estatisticas_manchester_diaria;`.
4. **Programação em PL/pgSQL:**
   * **Trigger de Proteção com `RAISE EXCEPTION`:** Crie uma Function + Trigger `BEFORE INSERT OR UPDATE` que impeça que um paciente com Protocolo Vermelho fique com status `Aguardando Atendimento` por mais de 0 minutos ou que seja alocado em um consultório ambulatorial azul, abortando a transação via `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Controle Transacional:** Crie a Procedure `pr_transferir_paciente_uti(p_atendimento_id INT, p_leito_uti_id INT)` declarando variáveis com ancoragem `%TYPE`, atualizando o status do atendimento para `Transferido UTI` e registrando log em tabela de auditoria, aplicando `COMMIT` explícito em caso de sucesso ou `ROLLBACK` em caso de erro.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Protocolo_Cor, Data_Hora_Chegada)` para a fila de chamada do painel.
   * **Índice Parcial:** `CREATE INDEX idx_ps_emergencia_ativa ON Atendimento_PS (ID_Atendimento_PS) WHERE Status_Atendimento = 'Em Atendimento';`.
   * **Índice Funcional:** `CREATE INDEX idx_paciente_cpf_limpo ON Paciente (REPLACE(REPLACE(CPF, '.', ''), '-', ''));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma consulta usando `WITH fila_classificada AS (...)` aplicando `DENSE_RANK() OVER (PARTITION BY Protocolo_Cor ORDER BY Data_Hora_Chegada ASC)` para gerar a posição na fila em tempo real de cada paciente dentro da sua faixa de gravidade.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente o plano de execução da query da fila demonstrando a troca de *Seq Scan* por *Bitmap Index Scan*.
8. **Particionamento Declarativo por Intervalo (`PARTITION BY RANGE`):**
   * Particione a tabela `Atendimento_PS` por mês com base no campo `Data_Hora_Chegada`. Crie partições mensais e comprove o *Partition Pruning* via `EXPLAIN`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Simule duas sessões no DBeaver onde dois enfermeiros tentam alocar dois pacientes graves simultaneamente no único leito livre do `Box Vermelho 01`, usando `FOR UPDATE` para serializar o acesso.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `atendimentos_emergencia`):**
   * Documento BSON rico com sinais vitais, histórico de cores e prescrições iniciais **incorporados** (*embedded*). Justifique tecnicamente por que o histórico do atendimento de urgência é uma fotografia imutável.
2. **Índices no MongoDB:**
   * Crie um índice composto `{ "triagem.cor": 1, "data_chegada": 1 }` e um índice multikey `{ "conduta_medicamentos.nome": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize atendimentos onde o paciente recebeu medicamentos com via de administração "IV" ou onde a saturação de O2 foi inferior a 90%.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira contendo obrigatoriamente `$match`, `$unwind`, `$group`, `$project` e `$sort` calculando:
     * O tempo médio de atendimento por cor de Manchester.
     * O ranking dos medicamentos mais administrados no Box de Emergência.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$push` para adicionar uma nova reavaliação médica no array de evolução clínica do paciente.
