# Plano Didático: Imersão em Tópicos Avançados de Banco de Dados (8 Horas)

Este plano condensa as lacunas curriculares de **Tópicos Avançados de Banco de Dados** em **duas sessões intensivas de 4 horas cada (total de 8h)**, combinando rigor conceitual com laboratórios práticos.

---

## 📅 Visão Geral da Distribuição

```mermaid
timeline
    title Cronograma da Imersão (8 Horas)
    section AULA 1 (4h) : Engenharia Relacional, Concorrência & Escala
      00:00 - 01:00 : Diagnóstico e EXPLAIN ANALYZE
      01:00 - 02:00 : Tuning de Consultas e Índices Avançados
      02:00 - 03:00 : Transações, MVCC, Locks e Deadlocks
      03:00 - 04:00 : Particionamento de Tabelas e JSONB Híbrido
    section AULA 2 (4h) : Paradigma NoSQL, MongoDB & Sistemas Distribuídos
      00:00 - 01:00 : Do Relacional ao NoSQL (Embed vs Reference)
      01:00 - 02:00 : Operações e Modelagem Rica no MongoDB
      02:00 - 03:00 : Aggregation Framework em Profundidade
      03:00 - 04:00 : Replicação, Sharding, CAP e Governança/LGPD
```

---

## 🕒 AULA 1: Engenharia Relacional, Concorrência e Alta Performance (4 Horas)

### Bloco 1.1 (00:00 - 01:00): Anatomia do Otimizador e Diagnóstico (`EXPLAIN ANALYZE`)
* **Fundamentos Teóricos:**
  * Como a query é processada: Parser ➔ Rewriter ➔ Planner/Optimizer ➔ Executor.
  * O papel das estatísticas do PostgreSQL (`pg_statistic`, `ANALYZE`).
  * `EXPLAIN` (estimativa puramente matemática) vs `EXPLAIN ANALYZE` (execução real com medição).
* **Decodificando a Saída do Otimizador:**
  * Métricas essenciais: `cost` (custo inicial `..` custo total), `rows` (estimativa vs real), `width` (tamanho em bytes), `actual time` e `loops`.
  * Nós de varredura: *Sequential Scan* (`Seq Scan`), *Index Scan*, *Index Only Scan*, *Bitmap Index Scan + Bitmap Heap Scan*.
* **Prática Guiada:**
  * Executar consultas em tabelas com milhares de linhas e comparar o tempo antes e após a criação de índices.

### Bloco 1.2 (01:00 - 02:00): Estratégias de Tuning e Algoritmos de Junção
* **Fundamentos Teóricos:**
  * Como o SGBD junta tabelas internamente:
    * `Nested Loop` (excelente para volumes pequenos com índice).
    * `Hash Join` (ótimo para tabelas médias/grandes sem índice prévio).
    * `Merge Join` (ideal quando ambas as fontes já estão ordenadas).
  * Impacto de funções não sargable em cláusulas `WHERE` (ex: `WHERE UPPER(nome) = ...` matando índices normais).
* **Prática Guiada:**
  * Reescrever consultas lentas, eliminando subconsultas redundantes e forçando índices de expressão e índices compostos estratégicos.

---

### ☕ Intervalo Didático (15 minutos)

---

### Bloco 1.3 (02:00 - 03:00): Concorrência, MVCC, Bloqueios e Deadlocks
* **Fundamentos Teóricos:**
  * **MVCC (Multi-Version Concurrency Control):** Por que "leituras nunca bloqueiam escritas, e escritas nunca bloqueiam leituras". Tuplas mortas, *xmin*, *xmax* e a necessidade do `VACUUM`.
  * **Níveis de Isolamento (ANSI SQL no Postgres):**
    * *Read Committed* (padrão): leituras veem apenas commits passados; sujeito a leituras não-repetíveis.
    * *Repeatable Read*: fotografia estática da transação; elimina *Phantom Reads*.
    * *Serializable*: impede anomalias de escrita concorrente (*Write Skew*).
  * **Tipos de Bloqueio (*Locks*):**
    * Bloqueios de linha pessimistas: `SELECT ... FOR UPDATE` e `SELECT ... FOR SHARE`.
    * Bloqueios de tabela exclusivos (`ALTER TABLE`, `DROP TABLE`).
  * **Anatomia do Deadlock:** Condições de corrida cíclica (Transação A espera B, que espera A).
* **Prática Guiada:**
  * Abrir duas conexões simultâneas no DBeaver e forçar uma colisão de agendamento de sala com `FOR UPDATE`, culminando em um deadlock monitorado em tempo real via `pg_locks`.

### Bloco 1.4 (03:00 - 04:00): Particionamento de Tabelas e Modelagem Híbrida (`JSONB`)
* **Fundamentos Teóricos:**
  * Particionamento declarativo nativo no PostgreSQL: quando uma tabela única atinge dezenas de milhões de linhas e degrada cache e índices.
  * Estratégias: Particionamento por Intervalo (`RANGE`), por Lista (`LIST`) e por Hash (`HASH`).
  * O mecanismo de *Partition Pruning* (como o banco descarta partições irrelevantes durante o plano).
  * Armazenamento Semi-estruturado: quando fugir da normalização estrita e usar colunas `JSONB` com índices invertidos (**GIN**).
* **Prática Guiada:**
  * Criar tabela particionada mensalmente para consultas hospitalares e consultar o `EXPLAIN` demonstrando o descarte automático de partições.

---

## 🕒 AULA 2: Paradigma NoSQL, MongoDB e Sistemas Distribuídos (4 Horas)

### Bloco 2.1 (00:00 - 01:00): Transição de Mentalidade: Relacional vs Orientado a Documentos
* **Fundamentos Teóricos:**
  * A crise da escalabilidade relacional sob tráfego massivo e schemas variáveis.
  * O Modelo de Dados em Documentos (JSON / BSON): auto-contido, hierárquico e flexível.
  * A regra de ouro da modelagem NoSQL: **Modelar pelos Padrões de Acesso (Read/Write Queries), não pela estrutura da entidade pura**.
  * A grande decisão arquitetural:
    * **Incorporar (*Embedding*):** Relações 1:1 e 1:N pequeno/delimitado; dados lidos e atualizados juntos (ex: itens da prescrição médica).
    * **Referenciar (*Referencing*):** Relações N:M, 1:N infinito (*unbounded growth*) ou dados frequentemente atualizados de forma autônoma.
* **Prática Guiada:**
  * Análise do [dados_hospital.csv](laboratorio-hospital/dados_hospital.csv) e desenho do documento ideal de Atendimento no MongoDB.

### Bloco 2.2 (01:00 - 02:00): Operações CRUD Avançadas e Operadores de Array no MongoDB
* **Fundamentos Teóricos:**
  * Tipos de dados BSON (ObjectId, Date, NumberDecimal, Arrays, Embedded Documents).
  * Consultas ricas dentro de listas de objetos:
    * `$elemMatch`: buscar dentro de arrays por múltiplas condições no mesmo elemento.
    * Operadores de projeção e filtragem: `$in`, `$all`, `$size`, `$exists`.
  * Atualizações atômicas em arrays: `$push`, `$pull`, `$addToSet`, operador posicional `$[]`.
* **Prática Guiada:**
  * Inserção dos atendimentos médicos com arrays de procedimentos e prescrições; busca por consultas com prescrições de dosagens específicas.

---

### ☕ Intervalo Didático (15 minutos)

---

### Bloco 2.3 (02:00 - 03:00): O Pipeline de Agregação (*Aggregation Framework*)
* **Fundamentos Teóricos:**
  * Por que NoSQL não usa `JOIN` tradicional: a esteira analítica modular do MongoDB (`aggregate([ ... ])`).
  * Estágios fundamentais da esteira:
    * `$match`: filtro inicial de alta performance (usa índice).
    * `$project` / `$addFields`: transformação e cálculo de atributos.
    * `$unwind`: desconstrução de arrays para análise individual de itens.
    * `$group`: agrupamento idêntico ao `GROUP BY` relacional, com acumuladores (`$sum`, `$avg`, `$push`, `$addToSet`).
    * `$lookup`: a junção no MongoDB (quando cruzar coleções é indispensável).
    * `$sort`, `$skip`, `$limit`: paginação e ordenação de dashboards.
* **Prática Guiada:**
  * Construir a esteira de faturamento hospitalar somando o valor faturado por especialidade e identificando os procedimentos mais prescritos.

### Bloco 2.4 (03:00 - 04:00): Arquitetura Distribuída, Alta Disponibilidade e Governança
* **Fundamentos Teóricos:**
  * **Teorema CAP:** Consistência (C), Disponibilidade (A) e Tolerância a Partição (P) — por que é matematicamente impossível ter os 3 em redes reais.
  * **Replicação (*Replica Sets*):** Primary (leitura e escrita) + Secondaries (leitura eventual e failover automático).
  * **Sharding:** Particionamento horizontal distribuído através de *Shard Keys*, *Config Servers* e *Mongos Routers*.
  * **Segurança e Governança:**
    * Criptografia em trânsito (TLS) e em repouso.
    * Conformidade com a **LGPD:** anonimização de dados médicos, trilhas de auditoria e exclusão segura.
* **Encerramento da Imersão:**
  * Apresentação e entrega do **Laboratório Prático End-to-End**.
