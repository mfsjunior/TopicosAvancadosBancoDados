# Modelo 05: Laboratório de Análises Clínicas e Laudos Multiparamétricos

**Domínio:** Medicina Diagnóstica, Análises Bioquímicas e Automação Laboratorial  
**Complexidade:** Alta (Estruturas Dinâmicas de Parâmetros, Valores de Referência Variáveis e Liberação por Lote)

---

## 📌 1. Cenário de Negócio
O Laboratório Central do hospital processa milhares de tubos de amostras biológicas (Sangue Total, Soro, Urina, Líquor) coletadas de pacientes internados e ambulatoriais:
* Um médico solicita um **Pedido de Exame** contendo múltiplos exames (ex: Hemograma Completo, Glicemia de Jejum, Perfil Lipídico, Coagulograma).
* Cada exame é decomposto em múltiplos **Parâmetros Analíticos** com resultados numéricos ou textuais, métodos de medição e faixas de **Valores de Referência** que variam dependendo da idade e sexo do paciente.
* As amostras são etiquetadas com códigos de barras e lidas por analisadores bioquímicos automatizados.
* A liberação final exige a validação técnica de um **Biomédico ou Farmacêutico-Bioquímico (CRBM/CRF)** e emissão de assinatura digital.

---

## 📄 2. Planilha Bruta de Entrada (`dados_laboratorio_analises.csv`)

Abaixo está o extrato exportado do sistema LIS (*Laboratory Information System*) do hospital (delimitador: ponto e vírgula `;`):

```csv
ID_Pedido_Exame;Data_Coleta;Paciente_CPF;Nome_Paciente;Idade;Sexo;Medico_Solicitante_CRM;Biomedico_Responsavel_CRBM;Tipo_Amostra_Tubo;Exame_Nome_TUSS;Parametros_Resultados_Referencia;Status_Laudo;Data_Liberacao
6001;25/10/2023 07:00;123.789.456-01;Graciliano Ramos;65;M;CRM 4455-SP;CRBM 11223-SP;Tubo EDTA Tampa Roxa;Hemograma Completo (403010);"Hemácias: 4.8 M/uL (Ref: 4.3-5.7), Hemoglobina: 14.2 g/dL (Ref: 13.5-17.5), Leucócitos: 6200 /uL (Ref: 4000-11000), Plaquetas: 210000 /uL (Ref: 150000-450000)";Liberado;25/10/2023 11:30
6002;25/10/2023 07:15;234.890.567-12;Rachel de Queiroz;72;F;CRM 8899-SP;CRBM 11223-SP;Tubo Gel Separador Amarelo;Perfil Glicêmico e Renal (403020);"Glicemia Jejum: 145 mg/dL [ALTERADO!] (Ref: 70-99), Creatinina: 1.6 mg/dL [ALTERADO!] (Ref: 0.6-1.1), Ureia: 58 mg/dL (Ref: 15-45)";Liberado;25/10/2023 12:00
6003;25/10/2023 08:00;345.901.678-23;Jorge Amado;55;M;CRM 4455-SP;CRBM 33445-SP;Frasco Estéril Tampa Vermelha;Urina Tipo I / EAS (403030);"Proteínas: Negativo, Glicose: Negativo, Leucócitos: 12000 /mL (Ref: até 10000), Bactérias: Presentes Moderadas";Pendente de Liberação;NULL
6004;25/10/2023 08:30;456.012.789-34;Clarice Lispector;40;F;CRM 1212-SP;CRBM 33445-SP;Tubo Citrato Tampa Azul;Coagulograma (403040);"Tempo de Protrombina (TP): 12.5 seg (Ref: 11-14), INR: 1.05 (Ref: 0.9-1.2), TTPA: 32 seg (Ref: 28-38)";Em Análise Técnica;NULL
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Paciente`, `Medico_Solicitante`, `Biomedico_Avaliador`, `Pedido_Exame`, `Tubo_Amostra`, `Exame_Catalogo`, `Parametro_Definicao` (com ref_min e ref_max por sexo) e `Resultado_Parametro_Item`.
   * Chaves primárias com `SERIAL` ou `UUID`, restrições de validação `CHECK (Sexo IN ('M', 'F'))`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Pedido_Exame`, crie a coluna `Bateria_Resultados_Json JSONB` com a árvore completa dos resultados do laudo (ex: `{"glicemia": 145, "creatinina": 1.6, "ureia": 58, "alteracoes_detectadas": true}`).
   * Crie o índice invertido `CREATE INDEX idx_laudos_gin ON Pedido_Exame USING GIN (Bateria_Resultados_Json);`.
   * Realize consulta utilizando o operador `@>` buscando laudos com `"alteracoes_detectadas": true`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_laudos_completos_paciente` unindo paciente, exames solicitados, resultados e nome do biomédico que assinou.
   * **Materialized View:** `vm_produtividade_biomedicos_mensal` com contagem total de exames laudados por profissional, com atualização concorrente via `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se o biomédico que está liberando o laudo possui inscrição ativa no CRBM e impeça a liberação caso existam parâmetros obrigatórios sem preenchimento, abortando com `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_assinar_e_liberar_laudo(p_pedido_id INT, p_biomedico_crbm VARCHAR)` declarando variáveis com ancoragem `%TYPE`, alterando o status para `Liberado`, preenchendo a `Data_Liberacao = NOW()` e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Paciente_ID, Data_Coleta DESC)` para prontuário histórico de exames.
   * **Índice Parcial:** `CREATE INDEX idx_laudos_urgentes_pendentes ON Pedido_Exame (ID_Pedido_Exame) WHERE Status_Laudo = 'Pendente de Liberação';`.
   * **Índice Funcional:** `CREATE INDEX idx_exame_nome_lower ON Exame_Catalogo (LOWER(Nome_Exame));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE comparando com `LAG(Valor_Resultado) OVER (PARTITION BY Paciente_ID, Parametro_ID ORDER BY Data_Coleta)` a evolução da taxa de glicose ou creatinina do paciente em relação ao exame imediatamente anterior.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Apresente a medição de buffer hit ao buscar histórico de exames com o índice composto ativo.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Resultado_Parametro_Item` por mês com base na `Data_Coleta`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Dois biomédicos abrem simultaneamente a tela de liberação do exame `ID 6003`. Demonstre como o uso de `FOR UPDATE` impede que ambos alterem e assinem o documento simultaneamente.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `laudos_laboratoriais`):**
   * Documento BSON rico contendo o array `parametros: [ { "nome": "Hemoglobina", "valor": 14.2, "ref": "13.5-17.5" }, ... ]`. Justifique por que essa flexibilidade é ideal para acomodar dezenas de exames com campos heterogêneos.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "paciente_cpf": 1, "data_coleta": -1 }` e índice multikey `{ "parametros.nome": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Escreva uma query com `$elemMatch` para localizar laudos onde o parâmetro "Glicemia Jejum" teve valor superior a 126 mg/dL.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `parametros`, agrupando com `$group` por nome do parâmetro para calcular o valor médio dos resultados e o total de exames realizados.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com o operador posicional `$[elem]` para corrigir um valor de parâmetro alterado de forma atômica no interior do array.
