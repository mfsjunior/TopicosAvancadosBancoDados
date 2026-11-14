# Modelo 08: Faturamento Hospitalar, Repasse Médico e Glosas (TUSS/TISS)

**Domínio:** Faturamento Médico, Contas Hospitalares, Convênios e Auditoria TISS/TUSS  
**Complexidade:** Alta (Múltiplas Regras Contábeis, Glosas Parciais e Repasse de Honorários)

---

## 📌 1. Cenário de Negócio
No Faturamento Hospitalar, cada alta ou procedimento gera uma **Conta Hospitalar** enviada para as operadoras de plano de saúde através do padrão nacional **TISS (Troca de Informações na Saúde Suplementar)**:
* A conta detalha Diárias de Quarto/UTI, Taxas de Sala, Gases Medicinais, Materiais e Medicamentos (tabela Brasíndice/Simpro) e Honorários Médicos (tabela **TUSS**).
* Os auditores do convênio analisam a conta e podem aplicar **Glosas Técnicas ou Administrativas** (recusa de pagamento por falta de autorização prévia, dosagem acima do protocolo ou ausência de relatório cirúrgico).
* O hospital pode aceitar a glosa ou entrar com um **Recurso de Glosa**.
* O hospital precisa calcular o **Repasse Médico Líquido** para os profissionais envolvidos, deduzindo a taxa de retenção hospitalar e eventuais glosas de responsabilidade do médico.

---

## 📄 2. Planilha Bruta de Entrada (`dados_faturamento_glosas.csv`)

Abaixo está o extrato exportado do sistema de faturamento hospitalar (delimitador: ponto e vírgula `;`):

```csv
ID_Conta_Hospitalar;Data_Fechamento;Paciente_CPF;Nome_Paciente;Convenio_Nome;CNPJ_Operadora;Itens_Faturados_TUSS_Taxas_Valores;Valor_Total_Cobrado;Glosas_Aplicadas_Motivo_Valor;Valor_Final_Aprovado;Repasse_Medico_CRM_Valor;Data_Recurso_Glosa;Status_Conta
2001;28/10/2023;123.111.222-33;Sérgio Buarque;Bradesco Saúde;98.765.432/0001-10;"Diária UTI (10101): R$ 2500.00, Taxa Monitorização (20202): R$ 300.00, Honorário Médico Visita (30303): R$ 400.00";3200.00;"Nenhuma";3200.00;"Dr. Cláudio Fontes (CRM 10203-SP): R$ 280.00 (Taxa Hosp: 30%)";NULL;Liquidada e Paga
2002;28/10/2023;234.222.333-44;Gilberto Freyre;Unimed Central;12.345.678/0001-90;"Artroscopia (307010): R$ 3800.00, Kit Paramentação Estéril (40404): R$ 450.00, Parafuso Titânio OPME (50505): R$ 1200.00";5450.00;"Glosa no Kit Paramentação (40404) por Falta de Autorização Prévia: R$ 450.00";5000.00;"Dr. Marcus Toledo (CRM 9988-SP): R$ 2660.00";29/10/2023;Recurso de Glosa Enviado
2003;28/10/2023;345.333.444-55;Darcy Ribeiro;SulAmérica Saúde;45.678.901/0001-50;"Consulta Pronto-Socorro (10102): R$ 180.00, Eletrocardiograma (1010): R$ 150.00";330.00;"Glosa Total no ECG (1010) por Ausência de Laudo Assinado: R$ 150.00";180.00;"Dr. Paulo Ventura (CRM 88771-SP): R$ 126.00";NULL;Glosa Aceita pelo Hospital
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Operadora_Plano`, `Conta_Hospitalar`, `Item_Conta_Faturado`, `Glosa_Aplicada`, `Recurso_Glosa` e `Repasse_Medico`.
   * Restrições `CHECK (Valor_Final_Aprovado >= 0)` e integridade em cascata para itens da conta.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Conta_Hospitalar`, crie a coluna `Metadados_XML_TISS_Json JSONB` (ex: `{"versao_tiss": "4.01.00", "numero_guia_prestador": "GUIA-9988", "lote_envio": 450, "glosas_notificadas": 1}`).
   * Crie o índice GIN `CREATE INDEX idx_tiss_gin ON Conta_Hospitalar USING GIN (Metadados_XML_TISS_Json);`.
   * Realize consulta utilizando o operador de existência `?` ou contenção `@>` buscando contas com `"glosas_notificadas": 1`.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_espelho_conta_hospitalar` trazendo detalhes dos itens, valores glosados e valor líquido por conta.
   * **Materialized View:** `vm_taxa_glosa_operadora` consolidando percentual de sinistros e perdas por convênio, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide se a soma de `Valor_Final_Aprovado + Valor_Glosado` ultrapassa o `Valor_Total_Cobrado`, abortando a transação via `RAISE EXCEPTION`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_fechar_lote_faturamento(p_operadora_id INT, p_mes_ano VARCHAR)` declarando variáveis com ancoragem `%TYPE`, travando as contas do lote, gerando o número de remessa contábil e aplicando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Operadora_ID, Data_Fechamento DESC)` para fechamentos contábeis.
   * **Índice Parcial:** `CREATE INDEX idx_contas_com_glosa ON Conta_Hospitalar (ID_Conta) WHERE Status_Conta LIKE '%Glosa%';`.
   * **Índice Funcional:** `CREATE INDEX idx_operadora_cnpj_clean ON Operadora_Plano (REGEXP_REPLACE(CNPJ, '[^0-9]', '', 'g'));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `SUM(Valor_Final_Aprovado) OVER (PARTITION BY Operadora_ID ORDER BY Data_Fechamento)` o faturamento acumulado de cada plano ao longo dos dias do mês.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Compare o plano de execução para recuperação de contas com glosa pendente com e sem o índice parcial.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Conta_Hospitalar` por ano/mês usando `PARTITION BY RANGE (Data_Fechamento)`.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * Enquanto a rotina contábil mensal fecha o lote de contas da Unimed, um operador tenta inserir uma nova despesa retroativa de oxigênio. Demonstre o uso de `SELECT ... FOR UPDATE` no lote para evitar alteração em conta em fechamento.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `contas_tiss`):**
   * Documento BSON incorporando o array de itens faturados e o histórico de glosas. Justifique a modelagem de contas médicas em NoSQL.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "convenio.nome": 1, "data_fechamento": -1 }` e índice multikey `{ "itens.codigo_tuss": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize contas hospitalares onde algum item do faturamento tenha sofrido glosa com motivo contendo "Autorização Prévia".
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Construa uma esteira com `$unwind` em `itens`, agrupando com `$group` por operadora para calcular o valor total faturado, o valor total glosado e o percentual de perda.
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$set` e `$push` registrando o envio do recurso de glosa de forma atômica no item correspondente.
