# Laboratório 05: Planner e EXPLAIN

## Objetivo
Deixar de "adivinhar" o que o banco de dados está fazendo e aprender a ler o Plano de Execução, que é a verdadeira visão raio-X de uma query.

## Conceitos
- `EXPLAIN` (Previsão / Planner)
- `EXPLAIN ANALYZE` (Execução Real)
- Seq Scan vs Index Scan vs Bitmap Heap Scan
- Custos (Costs), Rows e Buffers

## Procedimento (Nível 1 - Execução)

Vamos analisar a query de busca de vagas abertas com base num salário específico.
Execute:
```sql
EXPLAIN ANALYZE 
SELECT * FROM vaga WHERE salario > 10000;
```

**Lendo o resultado:**
- **Seq Scan**: O banco leu a tabela inteira do início ao fim.
- **cost=0.00..X**: O primeiro número é o custo inicial (para entregar a primeira linha). O segundo é o custo total.
- **rows=X**: A estimativa de linhas que o Planner achou que encontraria.
- **actual time=... rows=Y**: Quanto tempo demorou de verdade e quantas linhas realmente existiam (Compare `rows` estimado vs `rows` actual!).

## Investigação (Nível 2)
1. Rode `EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM candidato WHERE email = 'candidato100@email.com';`
2. Observe a seção `Buffers: shared hit=...`. O que significa um buffer "hit" em contraste com um "read"? 

## Desafio (Nível 3)
Você criou o índice parcial no laboratório anterior (`idx_vaga_aberta`), certo?
Escreva duas queries:
1. Uma buscando vagas com status `ENCERRADA`.
2. Outra buscando vagas com status `ABERTA`.
Faça um `EXPLAIN ANALYZE` em ambas. Prove usando o plano de execução que o PostgreSQL foi inteligente o suficiente para utilizar o Índice Parcial apenas na segunda query e ignorá-lo na primeira.

---
## Perguntas
- Se você tem um índice numa coluna, mas a sua query retorna 95% da tabela, o PostgreSQL vai usar o índice ou fazer um Seq Scan? Por quê?
- O que é Seletividade e como ela influencia a decisão do Planner?
