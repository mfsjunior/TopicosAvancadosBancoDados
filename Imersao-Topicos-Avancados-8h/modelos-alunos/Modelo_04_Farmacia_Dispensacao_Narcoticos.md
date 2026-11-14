# Modelo 04: Farmácia Hospitalar, Dispensação de Narcóticos e Estoque por Lote

**Domínio:** Farmácia Clínica, Logística de Medicamentos de Alto Custo e Controle Sanitário Portaria 344  
**Complexidade:** Alta (Rastreabilidade Estrita por Lote, Validade e Controle Concorrente de Saldos Físicos)

---

## 📌 1. Cenário de Negócio
A Farmácia Central do hospital gerencia o estoque e a dispensação de milhares de medicamentos. Entre eles, os **Medicamentos Controlados e Narcóticos (Portaria 344 da ANVISA)** exigem rastreabilidade inquebrável:
* Cada ampola ou comprimido liberado deve estar vinculado a uma **Prescrição Médica Válida** com CRM do prescritor.
* Cada movimentação exige registro de **Número do Lote**, **Data de Fabricação**, **Data de Validade** e **Fabricante**.
* A liberação física exige a conferência e assinatura de um **Farmacêutico Responsável (CRF)** e a conferência do saldo físico no cofre antes e depois da saída.
* Se dois técnicos de farmácia tentarem baixar o mesmo lote simultaneamente no sistema, o saldo não pode ficar negativo nem inconsistente (*Race Condition*).

---

## 📄 2. Planilha Bruta de Entrada (`dados_farmacia_narcoticos.csv`)

Abaixo está o extrato exportado do sistema de dispensação da farmácia hospitalar (delimitador: ponto e vírgula `;`):

```csv
ID_Dispensacao;Data_Hora_Dispensacao;Prescricao_Origem_ID;Paciente_CPF;Nome_Paciente;Leito_Destino;Farmaceutico_CRF;Nome_Farmaceutico;Medicamentos_Dispensados_Lotes_Qtd;Tipo_Receituario_Notificacao;Cofre_Armario;Saldo_Anterior_Atual_Lote;Status_Liberacao
7001;24/10/2023 09:15;3001;112.233.445-56;Mário de Andrade;Leito 02 - UTI;CRF-SP 45890;Dra. Luciana Vilela;"Morfina 10mg/ml Ampola (Lote: MOR-2023-A, Val: 30/11/2024, Qtd: 5 ampolas, SaldoAnt: 50, SaldoAtu: 45), Fentanil 50mcg/ml (Lote: FEN-998, Val: 15/08/2024, Qtd: 2 ampolas, SaldoAnt: 20, SaldoAtu: 18)";Notificação de Receita A (Amarela);Cofre Narcóticos Blindado 01;OK;Dispensada com Sucesso
7002;24/10/2023 10:00;3002;223.344.556-67;Oswald de Andrade;Quarto 304 - Clínica;CRF-SP 45890;Dra. Luciana Vilela;"Clonazepam 2.5mg/ml Gotas (Lote: CLO-112, Val: 20/05/2025, Qtd: 1 frasco, SaldoAnt: 15, SaldoAtu: 14)";Receita de Controle Especial B1 (Azul);Armário Controlados B;OK;Dispensada com Sucesso
7003;24/10/2023 10:30;3003;334.455.667-78;Tarsila do Amaral;Leito 01 - UTI;CRF-SP 88123;Dr. Renato Peixoto;"Morfina 10mg/ml Ampola (Lote: MOR-2023-A, Val: 30/11/2024, Qtd: 10 ampolas, SaldoAnt: 45, SaldoAtu: 35)";Notificação de Receita A (Amarela);Cofre Narcóticos Blindado 01;OK;Dispensada com Sucesso
7004;24/10/2023 11:00;3004;445.566.778-89;Anita Malfatti;Quarto 201 - Cirúrgica;CRF-SP 88123;Dr. Renato Peixoto;"Midazolam 15mg/3ml Ampola (Lote: MID-776, Val: 10/10/2023 [VENCIDO!], Qtd: 2 ampolas)";Notificação de Receita B (Azul);Cofre Narcóticos Blindado 02;Divergência de Validade;Bloqueada por Validade Vencida
```

---

## 🛠️ 3. Estruturas Complexas Obrigatórias (PostgreSQL)

O aluno deve implementar **todas** as estruturas abaixo em seu script `.sql`:

1. **Normalização e DDL Completo (3FN):**
   * Tabelas: `Medicamento`, `Lote_Medicamento`, `Cofre_Armazenamento`, `Farmaceutico`, `Prescricao_Origem`, `Dispensacao` e `Item_Dispensado`.
   * Chaves primárias com `SERIAL` ou `UUID`, restrição matemática `CHECK (Quantidade_Dispensada > 0)` e `CHECK (Saldo_Estoque >= 0)` para impedir saldo negativo no banco.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:**
   * Na tabela `Dispensacao`, crie a coluna `Dados_Portaria344_Json JSONB` (ex: `{"tipo_notificacao": "Receita A Amarela", "numero_serie_talonario": "A-8877", "comprador_rg": "12.345.678-SP", "conferido_por": "CRF-45890"}`).
   * Crie o índice GIN `CREATE INDEX idx_notificacao_gin ON Dispensacao USING GIN (Dados_Portaria344_Json);`.
   * Realize consulta utilizando `@>` para buscar dispensações de receituário Amarelo.
3. **Visões Clássicas e Materializadas:**
   * **View Clássica:** `vw_inventario_cofre_narcoticos` cruzando medicamento, lote, data de validade e saldo atual.
   * **Materialized View:** `vm_balanco_anvisa_mensal` consolidando entradas, saídas e perdas de substâncias da Portaria 344 para envio à autoridade sanitária, atualizada com `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em PL/pgSQL:**
   * **Função Gatilho (`RETURNS TRIGGER`) + Trigger:** Valide antes da inserção (`BEFORE INSERT`) em `Item_Dispensado` se a `Data_Validade` do lote é anterior à data atual. Caso esteja vencido, cancele a operação com `RAISE EXCEPTION 'Impossível dispensar medicamento: lote vencido em %!', OLD.Data_Validade`.
   * **Stored Procedure com `%TYPE` e Transação:** Crie a Procedure `pr_executar_baixa_medicamento(p_lote_id INT, p_quantidade INT, p_dispensacao_id INT)` declarando variáveis com ancoragem `%TYPE`, subtraindo o saldo do lote, registrando o log de rastreabilidade e executando `COMMIT`.
5. **Índices Estratégicos:**
   * **Índice B-Tree Composto:** `(Medicamento_ID, Data_Validade ASC)` para aplicar a regra FEFO (*First Expire, First Out*).
   * **Índice Parcial:** `CREATE INDEX idx_lotes_criticos ON Lote_Medicamento (ID_Lote) WHERE Saldo_Estoque <= 10;`.
   * **Índice Funcional:** `CREATE INDEX idx_lote_codigo_clean ON Lote_Medicamento (TRIM(UPPER(Codigo_Lote)));`.
6. **SQL Analítico (CTE + Window Functions):**
   * Escreva uma query com CTE calculando com `SUM(Quantidade_Dispensada) OVER (PARTITION BY Medicamento_ID ORDER BY Data_Hora_Dispensacao)` a curva cumulativa de consumo de cada narcótico no mês.
7. **Diagnóstico com `EXPLAIN (ANALYZE, BUFFERS)`:**
   * Demonstre o ganho de desempenho ao consultar lotes por validade usando o índice FEFO.
8. **Particionamento Declarativo (`PARTITION BY RANGE`):**
   * Particione a tabela `Dispensacao` por trimestre. Crie partições e valide a poda de partição.
9. **Simulação de Concorrência e Bloqueio (`SELECT ... FOR UPDATE`):**
   * O lote `MOR-2023-A` possui apenas 5 ampolas restantes. O Farmacêutico 1 tenta dispensar 4 ampolas e o Farmacêutico 2 tenta dispensar 3 ampolas ao mesmo tempo. Demonstre o bloqueio com `FOR UPDATE` evitando saldo negativo.

---

## 🍃 4. Estruturas Complexas Obrigatórias (MongoDB)

1. **Modelagem de Documentos (Collection `dispensacoes_narcoticos`):**
   * Projete o documento incorporando os medicamentos e lotes dispensados na saída. Justifique a separação entre a collection de `estoque_lotes` e o histórico de `dispensacoes`.
2. **Índices no MongoDB:**
   * Crie índice composto `{ "data_hora": 1, "leito_destino": 1 }` e índice multikey `{ "itens.lote": 1 }`.
3. **Consulta Avançada com `$elemMatch`:**
   * Localize dispensações onde qualquer item envolva o lote "MOR-2023-A" com quantidade superior a 3 ampolas.
4. **Pipeline de Agregação (*Aggregation Framework*):**
   * Crie uma esteira com `$match`, `$unwind` em `itens`, `$group`, `$project` e `$sort` calculando o consumo total de ampolas de cada medicamento por setor de destino (UTI vs Bloco Cirúrgico).
5. **Atualização Atômica:**
   * Demonstre o comando `updateOne` com `$inc: { "saldo_disponivel": -5 }` na coleção de lotes para baixa atômica de inventário.
