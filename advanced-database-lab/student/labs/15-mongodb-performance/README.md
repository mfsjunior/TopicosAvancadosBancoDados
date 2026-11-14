# Laboratório 14: MongoDB Performance e Índices

## Objetivo
Entender as mecânicas de Índices, Compound Indexes e o comando EXPLAIN dentro do ecossistema MongoDB, comparando-o com o motor relacional.

## Conceitos
- `createIndex()`
- Compound Index (Índices Compostos e a regra ESR)
- Multikey Indexes (Índices de Array)
- `.explain("executionStats")`

## Procedimento (Nível 1 - Execução)

Rode no terminal mongosh:
1. Gere alguns milhares de documentos falsos simples:
```javascript
for (var i = 1; i <= 50000; i++) {
   db.log_eventos.insertOne({ "usuario": "user"+(i%100), "acao": "CLICK", "timestamp": new Date() })
}
```

2. Analise uma query (sem rodá-la no escuro):
```javascript
db.log_eventos.find({ "usuario": "user50" }).explain("executionStats")
```

3. Olhe o output. Procure por `"stage": "COLLSCAN"` (O equivalente ao Seq Scan do Postgres). Quantos documentos o Mongo examinou (`totalDocsExamined`)? E quantos ele retornou (`nReturned`)?

## Investigação (Nível 2)

Crie o índice para a coluna `usuario`:
```javascript
db.log_eventos.createIndex({ usuario: 1 })
```
*(O `1` significa ordem ascendente, `-1` seria descendente).*

Rode o `explain` novamente e procure a palavra `IXSCAN` (Index Scan). Quantos `totalDocsExamined` o motor teve que visitar dessa vez? A queda do número de documentos examinados é a prova de um índice bem-sucedido.

## Desafio (Nível 3) - O Paradoxo do Multikey
Volte para o seu banco `adv_curriculos` (`use adv_curriculos`).
Lembra que o João Silva tem um array de `skills`?
Se criarmos um índice: `db.curriculos.createIndex({ skills: 1 })`, o MongoDB cria automaticamente um **Multikey Index**.
**Problema:** Você NÃO pode criar um Índice Composto (Compound) onde DOIS dos campos indexados sejam Arrays. 
Por que a matemática proíbe a indexação composta de dois arrays no modelo de B-Tree invertida do MongoDB? Como o índice cresceria exponencialmente (Produto Cartesiano) se você fizesse isso?

---
## Perguntas
- O que é o TTL (Time-To-Live) Index no MongoDB e por que ele é perfeito para tabelas de Logs ou Carrinhos de Compra em E-Commerce?
- O MongoDB aplica a regra **ESR (Equality, Sort, Range)** para a ordem ideal de índices compostos. Pesquise e explique por que a Coluna de Ordenação (Sort) tem que vir ANTES da coluna de Faixa de Valores (Range) na construção do índice.
