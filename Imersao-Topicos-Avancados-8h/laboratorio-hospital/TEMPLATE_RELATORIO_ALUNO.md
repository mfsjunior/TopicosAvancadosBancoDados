# Relatório Prático: Laboratório Integrador de Banco de Dados
## Da Planilha Bruta à Arquitetura Relacional (PostgreSQL) e NoSQL (MongoDB)

**Disciplina:** Tópicos Avançados de Banco de Dados  
**Professor:** Milton Santos  
**Estudante:** [Preencha seu Nome Completo]  
**Matrícula:** [Preencha sua Matrícula] | **Turma:** [Preencha sua Turma/Curso]  
**Data de Entrega:** [DD/MM/AAAA]

---

## 📄 PÁGINA 1: Diagnóstico de Violações na Planilha (`dados_hospital.csv`)

> **Instrução:** Identifique e descreva com suas próprias palavras as 3 principais violações de normalização que você encontrou na planilha original [`dados_hospital.csv`](dados_hospital.csv) e como elas devem ser corrigidas no modelo relacional:

| Regra Violada | Colunas Afetadas no CSV | Problema Técnico Identificado | Como foi resolvido no PostgreSQL (3FN) |
| :--- | :--- | :--- | :--- |
| **1ª Forma Normal (1FN)**<br/>*Atributos Multivalorados* | *[Preencha as colunas]* | *[Explique por que viola a 1FN]* | *[Explique qual tabela você criou para normalizar]* |
| **2ª Forma Normal (2FN)**<br/>*Dependência Parcial* | *[Preencha as colunas]* | *[Explique por que viola a 2FN]* | *[Explique qual tabela você criou para normalizar]* |
| **3ª Forma Normal (3FN)**<br/>*Dependência Transitiva* | *[Preencha as colunas]* | *[Explique por que viola a 3FN]* | *[Explique qual tabela você criou para normalizar]* |

---

## 📄 PÁGINA 2: Desafio 1 — Diagnóstico com `EXPLAIN ANALYZE` (PostgreSQL)

### 1. Código SQL Desenvolvido pelo Estudante:
```sql
-- [Escreva aqui a sua consulta SQL completa para identificar o médico com mais procedimentos]



```

### 2. Print do Resultado e do Plano de Execução no DBeaver / Terminal:
> *(Cole aqui a captura de tela nítida da sua execução mostrando o resultado da consulta e a árvore do EXPLAIN ANALYZE)*
> 
> ```
> [COLE AQUI O PRINT DO SEU DBEAVER / TERMINAL COM O EXPLAIN ANALYZE]
> ```

### 3. Parecer Técnico sobre o Plano de Execução (1 Parágrafo):
> **Análise do Aluno:**  
> *[Escreva aqui um parágrafo analisando: Qual médico realizou mais procedimentos no período? Qual foi o nó de junção escolhido pelo otimizador do PostgreSQL (Nested Loop, Hash Join ou Merge Join)? Por que o banco escolheu esse algoritmo considerando o volume de dados da tabela?]*

---

## 📄 PÁGINA 3: Desafios 2 e 3 — MongoDB & Decisão de Arquitetura

### 1. Desafio 2: Pipeline Analítico no MongoDB (`$match` + `$unwind` + `$group`)
```javascript
// [Escreva aqui o seu código do pipeline de agregação no MongoDB]



```

### 2. Print da Consulta e Resultado no DBeaver / `mongosh`:
> *(Cole aqui a captura de tela nítida mostrando o pipeline executado no MongoDB e o documento retornado)*
> 
> ```
> [COLE AQUI O PRINT DO SEU DBEAVER / MONGOSH COM O RESULTADO]
> ```

---

### 3. Desafio 3: Parecer de Arquitetura para Exames Médicos de 50MB (1 Parágrafo Obrigatório)

> **Decisão de Engenharia do Estudante:**  
> *[Escreva aqui 1 parágrafo técnico justificando: As imagens de Ressonância Magnética de 50MB podem ser salvas diretamente dentro do documento BSON do MongoDB? Qual é o limite físico do MongoDB? Qual é a arquitetura moderna recomendada (S3/MinIO vs GridFS) para armazenar esse arquivo e como o banco de dados deve referenciá-lo?]*
