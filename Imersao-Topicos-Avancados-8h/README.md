# Imersão: Tópicos Avançados de Banco de Dados (8 Horas)

Este diretório contém a síntese completa do conteúdo avançado de Banco de Dados distribuído em **2 aulas intensivas de 4 horas cada (total de 8h)**, além de um **Laboratório Prático End-to-End** que parte da planilha bruta hospitalar ([dados_hospital.csv](laboratorio-hospital/dados_hospital.csv)) até a modelagem física relacional (PostgreSQL) e orientada a documentos (MongoDB).

---

## 📁 Estrutura da Pasta

| Arquivo / Diretório | Descrição |
| :--- | :--- |
| **[`Plano_de_Aulas_8h.md`](Plano_de_Aulas_8h.md)** | Cronograma detalhado hora a hora das duas aulas de 4h para o professor conduzir a turma. |
| **[`Aula01_Performance_Concorrencia_PostgreSQL.md`](Aula01_Performance_Concorrencia_PostgreSQL.md)** | Guia didático da **Aula 1 (4h)**: Planos de Execução (`EXPLAIN ANALYZE`), Tuning, Concorrência, Níveis de Isolamento, Locks, Deadlocks e Particionamento. |
| **[`Aula02_NoSQL_MongoDB_Arquitetura_Distribuida.md`](Aula02_NoSQL_MongoDB_Arquitetura_Distribuida.md)** | Guia didático da **Aula 2 (4h)**: Paradigma NoSQL, Modelagem em Documentos (Embed vs Reference), Aggregation Framework, Sharding/Replicação, Teorema CAP e Segurança/LGPD. |
| **[`laboratorio-hospital/`](laboratorio-hospital/)** | Laboratório unificado completo a partir de dados hospitalares reais. |
| ├── **[`dados_hospital.csv`](laboratorio-hospital/dados_hospital.csv)** | Planilha CSV desestruturada gerada pela recepção do hospital (Arquivo de entrada). |
| ├── **[`Laboratorio_End_to_End_Hospital.md`](laboratorio-hospital/Laboratorio_End_to_End_Hospital.md)** | Roteiro prático com desafios, diagramas conceituais e comparações arquiteturais. |
| ├── **[`Guia_Choque_de_Realidade_Quebrando_Vicio_SQL.md`](laboratorio-hospital/Guia_Choque_de_Realidade_Quebrando_Vicio_SQL.md)** | Guia didático fundamental: Como quebrar dogmas de 1970, descompasso de impedância e pensar em documentos. |
| ├── **[`01_schema_relacional_postgres.sql`](laboratorio-hospital/01_schema_relacional_postgres.sql)** | Script SQL executável (DDL normalizado 3FN, carga, índices seletivos, simulação de lock/concorrência). |
| └── **[`02_schema_nosql_mongodb.js`](laboratorio-hospital/02_schema_nosql_mongodb.js)** | Script MongoDB (`mongosh`/DBeaver) com documentos ricos, operadores de array e pipelines de agregação. |
| **[`Tutorial_Subir_Bases_Containers.md`](Tutorial_Subir_Bases_Containers.md)** | **Guia Passo a Passo:** Como subir os containers Docker (PostgreSQL 15+ e MongoDB 6+), conectar e injetar as bases hospitalares via CLI ou DBeaver. |
| **[`modelos-alunos/`](modelos-alunos/)** | **14 Modelos Complexos Numerados (01 a 14)** para distribuição individual/em grupo para os alunos realizarem todo o ciclo prático. |

---

## 🎯 Objetivos de Aprendizagem

1. **Dominar Diagnóstico e Otimização:** Sair da intuição e passar a analisar planos de execução (`EXPLAIN ANALYZE`) identificando gargalos reais.
2. **Garantir Integridade Transacional em Alto Volume:** Compreender como o banco gerencia escrita concorrente (Locks, MVCC e níveis de isolamento) sem travar o sistema.
3. **Pensar Multi-Paradigma:** Saber exatamente quando usar o modelo relacional estrito (PostgreSQL) e quando migrar/combinar com o modelo NoSQL orientado a documentos (MongoDB).
