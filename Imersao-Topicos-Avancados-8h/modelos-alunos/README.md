# Catálogo de Desafios Práticos: 14 Modelos Complexos de Banco de Dados

**Disciplina:** Tópicos Avançados de Banco de Dados  
**Objetivo:** Cada aluno ou equipe receberá **um modelo numerado exclusivo**. Cada modelo apresenta um cenário real de alta complexidade derivado do ecossistema hospitalar, partindo de uma planilha bruta desnormalizada (padrão CSV) e exigindo o cumprimento do ciclo completo de engenharia de dados: **Normalização Relacional (PostgreSQL)** e **Modelagem NoSQL Orientada a Documentos (MongoDB)**.

---

## 📋 Grade de Distribuição dos 14 Modelos

| Nº | Arquivo do Desafio | Domínio Hospitalar Especializado | Gargalo Principal de Concorrência / NoSQL |
| :---: | :--- | :--- | :--- |
| **01** | [`Modelo_01_Pronto_Socorro_Triagem.md`](Modelo_01_Pronto_Socorro_Triagem.md) | Pronto-Socorro & Triagem Manchester | Alocação de Box Vermelho (`FOR UPDATE`) / Pipeline Tempo de Espera |
| **02** | [`Modelo_02_Bloco_Cirurgico_Anestesia.md`](Modelo_02_Bloco_Cirurgico_Anestesia.md) | Bloco Cirúrgico & Equipes Multiprofissionais | Conflito de Sala + Equipamento / Subdocumentos de Equipe Cirúrgica |
| **03** | [`Modelo_03_UTI_Parametros_Vitais.md`](Modelo_03_UTI_Parametros_Vitais.md) | UTI & Monitoramento de Leitos (Time-Series) | Transferência Urgente de Leito / Modelagem Bucket de Sensores |
| **04** | [`Modelo_04_Farmacia_Dispensacao_Narcoticos.md`](Modelo_04_Farmacia_Dispensacao_Narcoticos.md) | Farmácia Hospitalar & Narcóticos (Port. 344) | Baixa de Estoque Concorrente por Lote / Rastreabilidade de Ampolas |
| **05** | [`Modelo_05_Laboratorio_Analises_Clinicas.md`](Modelo_05_Laboratorio_Analises_Clinicas.md) | Laboratório Clínico & Laudos Multiparamétricos | Liberação de Laudo / Consultas em Arrays com `$elemMatch` |
| **06** | [`Modelo_06_Diagnostico_Imagem_PACS.md`](Modelo_06_Diagnostico_Imagem_PACS.md) | Centro de Imagem (RX, Tomografia, PACS/DICOM) | Tempo de Higienização de Sala de Tomografia / Metadados DICOM |
| **07** | [`Modelo_07_Banco_de_Sangue_Hemoterapia.md`](Modelo_07_Banco_de_Sangue_Hemoterapia.md) | Banco de Sangue & Fracionamento de Bolsas | Reserva Exclusiva O-Negativo / Ciclo de Vida da Bolsa de Sangue |
| **08** | [`Modelo_08_Faturamento_Glosas_TUSS.md`](Modelo_08_Faturamento_Glosas_TUSS.md) | Faturamento Hospitalar & Glosas TISS/TUSS | Fechamento de Lote Contábil / Pipeline de Glosas por Convênio |
| **09** | [`Modelo_09_Central_Esterilizacao_CME.md`](Modelo_09_Central_Esterilizacao_CME.md) | Central de Esterilização de Materiais (CME) | Liberação de Kit Cirúrgico Estéril / Rastreamento de Autoclaves |
| **10** | [`Modelo_10_Maternidade_Neonatal.md`](Modelo_10_Maternidade_Neonatal.md) | Maternidade, Partos & Berçário Neonatal | Alocação Mãe-Bebê em Alojamento Conjunto / Parto Gemelar no BSON |
| **11** | [`Modelo_11_Oncologia_Quimioterapia.md`](Modelo_11_Oncologia_Quimioterapia.md) | Oncologia & Protocolos Quimioterápicos | Liberação de Manipulação por Plaquetas / Linha de Cuidado |
| **12** | [`Modelo_12_Hemodialise_Sessoes_Renais.md`](Modelo_12_Hemodialise_Sessoes_Renais.md) | Centro de Diálise & Reúso de Capilares | Limite Máximo de Reúso do Filtro / Balanço Hídrico em Documento |
| **13** | [`Modelo_13_Hotelaria_Giro_Leitos.md`](Modelo_13_Hotelaria_Giro_Leitos.md) | Hotelaria Hospitalar & Limpeza Terminal | Liberação de Leito Desinfetado / Métricas de Turnaround Time |
| **14** | [`Modelo_14_Telemedicina_Prontuario_Digital.md`](Modelo_14_Telemedicina_Prontuario_Digital.md) | Telemedicina & Prontuário Digital ICP-Brasil | Invalidação de Token de Chamada / Receitas Digitais e LGPD |

---

## 🏆 Matriz Mandatória de Estruturas Complexas (Checklist de Entrega)

Para obter a nota máxima no laboratório, cada aluno ou grupo **deve obrigatoriamente construir TODAS as seguintes estruturas avançadas** aplicadas ao seu modelo específico:

### Bloco A: Engenharia Relacional (PostgreSQL)
1. **Normalização 3FN & DDL:** Criação de tabelas com chaves primárias artificiais (`SERIAL` ou `UUID`), chaves compostas em associativas N:M, restrições `CHECK`, `UNIQUE` e integridade referencial com `ON DELETE CASCADE` ou `ON DELETE RESTRICT`.
2. **Coluna Semi-estruturada `JSONB` com Índice GIN:** Pelo menos uma tabela com campo `JSONB` indexado por `CREATE INDEX ... USING GIN`, consultado via operador de contenção (`@>`) ou extração (`->>`).
3. **Visões Clássicas e Materializadas:**
   * 1 `VIEW` analítica simples que encapsule consultas com múltiplos `JOINs`.
   * 1 `MATERIALIZED VIEW` física com índice único e comando de atualização concorrente: `REFRESH MATERIALIZED VIEW CONCURRENTLY`.
4. **Programação em Banco (PL/pgSQL):**
   * **1 Função Gatilho (`RETURNS TRIGGER`):** Validação de regra de negócio complexa interceptando linhas com `NEW`/`OLD` e bloqueando operações indevidas com `RAISE EXCEPTION`.
   * **1 Trigger:** Vinculado à tabela via `BEFORE/AFTER INSERT/UPDATE/DELETE FOR EACH ROW`.
   * **1 Stored Procedure (`PROCEDURE`):** Chamada via `CALL`, utilizando variáveis com ancoragem estrita (`%TYPE`), cópia de linha (`%ROWTYPE`) ou cursor/registro genérico (`RECORD`), gerenciando explicitamente transações internas com blocos de `COMMIT` e `ROLLBACK`.
5. **Estratégia de Índices Avançados:**
   * 1 Índice B-Tree Composto com colunas ordenadas por seletividade.
   * 1 Índice Parcial condicional (`WHERE ...`) para focar em fatias críticas de dados (ex: cancelamentos, pendências ou emergências).
   * 1 Índice Funcional / Expressão (ex: `UPPER(nome)` ou extração de data).
6. **SQL Analítico Avançado:**
   * 1 Consulta sofisticada combinando **CTEs (`WITH`)** e **Window Functions** (`OVER (PARTITION BY ... ORDER BY ...)` com `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()` ou agregação cumulativa).
7. **Diagnóstico & Tuning com EXPLAIN:**
   * Apresentar o plano de execução via `EXPLAIN (ANALYZE, BUFFERS)` demonstrando a eliminação de *Seq Scan* e redução de custo de I/O em buffer antes e após a criação dos índices.
8. **Concorrência e Bloqueios Transacionais:**
   * Simulação prática entre duas sessões demonstrando bloqueio pessimista via `SELECT ... FOR UPDATE` para evitar condições de corrida (*Race Conditions*) no negócio.
9. **Particionamento Declarativo:**
   * Pelo menos uma tabela de grande volume particionada nativamente (`PARTITION BY RANGE` ou `LIST`), com suas partições filhas e validação de poda de partição (*Partition Pruning*) no `EXPLAIN`.

### Bloco B: Engenharia NoSQL (MongoDB)
10. **Modelagem Orientada a Documentos e Aggregation:**
    * Documento BSON rico com justificativa arquitetural do dilema de **Incorporação (*Embedding*) vs Referência (*Referencing*)**.
    * Criação de **Índices no MongoDB** (índice composto e índice multikey em arrays).
    * Consultas avançadas em arrays utilizando o operador **`$elemMatch`** e operadores de conjunto (`$in`, `$all`).
    * **Pipeline de Agregação (*Aggregation Framework*)** completo contendo no mínimo os estágios:
      * `$match`: Filtro seletivo inicial.
      * `$unwind`: Desconstrução atômica de arrays de subdocumentos.
      * `$group`: Agrupamento analítico com acumuladores (`$sum`, `$avg`, `$push`, `$addToSet`).
      * `$project`: Formatação, projeção e arredondamento de campos.
      * `$sort`: Ordenação dos resultados gerenciais.
    * Demonstração de atualização atômica em documento ou array (`$inc`, `$push` ou operador posicional `$[ ]`).
