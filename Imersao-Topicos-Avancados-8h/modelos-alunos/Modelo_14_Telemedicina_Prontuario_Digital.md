# Modelo 14: Telemedicina, Prontuário Digital e Assinatura ICP-Brasil

**Domínio:** Saúde Digital, Telemedicina, Criptografia em Repouso, Assinatura Digital e LGPD  
**Complexidade:** Alta (Trilhas de Auditoria Estritas, Invalidação de Tokens de Vídeo e Assinatura Criptográfica)

---

## 📌 1. Cenário de Negócio
A plataforma de Telemedicina do hospital permite consultas remotas por videoconferência com segurança de ponta a ponta:
* O paciente acessa uma sala virtual através de um **Token Criptográfico Temporário com tempo de expiração curto**.
* O médico atende o paciente, registra o prontuário eletrônico e emite a **Receita Médica Digital com Certificação Digital ICP-Brasil (Padrão A3/Nuvem)**.
* Cada receita gerada possui um **Hash Criptográfico SHA-256** assinado, permitindo que farmácias validem a autenticidade do documento no portal oficial do CFM/ITI.
* **Segurança e LGPD (Lei Geral de Proteção de Dados):**
  * Toda conexão registra metadados de auditoria: IP de Origem, Navegador, Termo de Consentimento Livre e Esclarecido (TCLE) com timestamp do aceite.
  * O token da chamada de vídeo deve ser **invalidado imediatamente** assim que o médico encerra a sessão.

---

## 📄 2. Planilha Bruta de Entrada (`dados_telemedicina_prontuario.csv`)

Abaixo está o extrato exportado da plataforma de teleatendimento (delimitador: ponto e vírgula `;`):

```csv
ID_Teleconsulta;Data_Hora_Agendada;Data_Hora_Inicio_Fim;Paciente_CPF;Nome_Paciente;IP_Origem_Conexao;Medico_CRM;Nome_Medico;Especialidade;Plataforma_Sala_Virtual_Token;Termo_LGPD_Aceito_Timestamp;Hipotese_Diagnostica_CID10;Prescricao_Hash_Assinatura_ICP;Status_Teleconsulta
9901;03/11/2023 14:00;14:02 às 14:28;111.888.555-99;Manoel de Barros;189.120.45.10;CRM 5511-SP;Dr. Ariano Suassuna;Psiquiatria;tok_sec_9901_abc123xyz (Expira: 14:35);Aceito em 03/11/2023 13:58:12 (v2.1);F32.1 - Episódio Depressivo Moderado;SHA256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855 (Certificado A3 CFM);Concluída com Receita Emitida
9902;03/11/2023 14:30;14:35 às 14:50;222.999.666-00;Hilda Hilst;201.88.12.5;CRM 6622-SP;Dra. Cora Coralina;Dermatologia;tok_sec_9902_def456uvw (Expira: 15:00);Aceito em 03/11/2023 14:29:05 (v2.1);L70.0 - Acne Vulgar;SHA256: d41d8cd98f00b204e9800998ecf8427e (Certificado Nuvem);Concluída com Receita Emitida
9903;03/11/2023 15:00;15:00 às 15:05;333.000.777-11;João Cabral de Melo Neto;177.20.100.80;CRM 5511-SP;Dr. Ariano Suassuna;Psiquiatria;tok_sec_9903_ghi789rst (Expira: 15:35);Recusado pelo Paciente;NULL;NULL;Cancelada por Recusa do Consentimento LGPD
9904;03/11/2023 15:30;15:31 às 15:32;444.111.888-22;Carlos Drummond de Andrade;186.250.90.1;CRM 6622-SP;Dra. Cora Coralina;Dermatologia;tok_sec_9904_jkl012mno (Expira: 16:00);Aceito em 03/11/2023 15:28:44 (v2.1);NULL;NULL;Interrompida por Queda de Conexão
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente`, `Medico_Telemedicina`, `Sessao_Teleconsulta`, `Log_Auditoria_LGPD`, `Receita_Digital_ICP` e `Certificado_Digital`.
   * Restrições `CHECK (Duracao_Segundos >= 0)` e `UNIQUE` no token e no hash da prescrição.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Log_Auditoria_LGPD`, crie a coluna `Metadados_Auditoria_Json JSONB` (ex: `{"user_agent": "Chrome/118", "geolocalizacao_ip": "São Paulo, SP", "versao_tcle": "2.1", "consentimento_gravacao": false}`).
   * Crie o índice GIN `CREATE INDEX idx_auditoria_lgpd_gin ON Log_Auditoria_LGPD USING GIN (Metadados_Auditoria_Json);`.
   * Realize consulta utilizando `@>` para buscar conexões com `"consentimento_gravacao": false`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_consultas_com_receita_assinada` trazendo paciente, médico, especialidade e hash da receita para conferência rápida de farmácias.
   * **Materialized View:** `vm_taxa_sucesso_telemedicina` acumulando chamadas concluídas versus canceladas por instabilidade de rede ou recusa de consentimento, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se a teleconsulta possui o registro de consentimento LGPD aceito antes de permitir a emissão de qualquer receita digital ou gravação do prontuário, abortando com `RAISE EXCEPTION 'VIOLAÇÃO LGPD: Proibido registrar atendimento sem consentimento prévio do titular!'`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_encerrar_teleconsulta(p_teleconsulta_id INT, p_duracao INT, p_hash_receita VARCHAR)` declarando variáveis com ancoragem `%TYPE`, invalidando o token de vídeo, atualizando o status para `Concluída` e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Medico_ID, Data_Hora_Agendada)` para agenda remota do profissional.
   * **Índice Parcial:** `CREATE INDEX idx_chamadas_em_andamento ON Sessao_Teleconsulta (ID_Teleconsulta) WHERE Status_Teleconsulta LIKE '%Conexão%';`.
   * **Índice Funcional:** `CREATE INDEX idx_hash_receita_upper ON Receita_Digital_ICP (UPPER(Hash_SHA256));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `AVG(Duracao_Segundos) OVER (PARTITION BY Especialidade)` o tempo médio de consulta remota por especialidade médica.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Compare o plano de busca de chamadas ativas com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Log_Auditoria_LGPD` por mês com base no timestamp da conexão.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Ao encerrar a sessão de teleconsulta, o médico grava o laudo e invalida o token da sala virtual. Demonstre o uso de `SELECT ... FOR UPDATE` no token para garantir sua revogação atômica imediata.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `teleconsultas`):**
   * Projete o documento incorporando as queixas clínicas, hipóteses diagnósticas em formato flexível e a receita digital. Justifique a modelagem de prontuários eletrônicos no MongoDB.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "medico_crm": 1, "data_agendada": -1 }` e índice **TTL (Time-To-Live)** `{ "data_expiracao_token": 1 }` com expiração automática em 3600 segundos.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize teleconsultas onde a hipótese diagnóstica envolva o CID "F32.1" e o termo LGPD tenha sido formalmente aceito.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$group` calculando a duração média da chamada em minutos e o percentual de pacientes que recusaram o termo de consentimento por especialidade.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` invalidando o token de vídeo com `$set: { "token_ativo": false, "status": "Encerrada" }` de forma atômica.
