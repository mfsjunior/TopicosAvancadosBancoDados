# Laboratório 03: SQL Avançado

## Objetivo
Trabalhar com consultas de alta complexidade em relatórios analíticos sem precisar retirar os dados do banco. Aprender a utilizar Common Table Expressions (CTEs), Subqueries e Window Functions.

## Conceitos Teóricos

### 1. Subqueries (Subconsultas)
São consultas aninhadas dentro de outra consulta maior. Podem ser usadas para retornar um único valor (escalar) para ser usado como filtro, ou uma lista de valores (usando `IN` ou `EXISTS`). Subqueries podem ser independentes ou **correlacionadas** (quando a subquery faz referência a uma coluna da query externa, executando uma vez para cada linha).

### 2. CTEs (Common Table Expressions) via `WITH`
Uma CTE permite definir blocos de consultas temporárias e nomeadas que existem apenas durante a execução de uma instrução SQL. O principal benefício é a **legibilidade**: elas quebram queries gigantes em pequenos pedaços lógicos e lineares, além de permitirem a criação de consultas recursivas (hierarquias).

### 3. Expressões Condicionais (`CASE`)
O `CASE` é o "if-else" do banco de dados. Ele permite criar novas colunas virtuais com base em condições lógicas avaliadas linha a linha, transformando dados brutos em categorizações amigáveis (ex: transformar `salario > 9000` na string `'Alto'`) sem precisar levar o dado para o backend da aplicação.

### 4. Window Functions (Funções de Janela)
As Window Functions são o recurso analítico mais poderoso do SQL moderno. Elas permitem realizar cálculos ao longo de um conjunto de linhas (a "janela") **sem achatar (colapsar) o resultado**. 
- Quando você usa o `GROUP BY`, você "espreme" 10 linhas em 1 linha de resumo. Você perde o detalhe.
- Com *Window Functions* (usando a cláusula `OVER`), você mantém as 10 linhas visíveis, mas consegue colocar uma coluna extra ao lado delas contendo a média do grupo inteiro, ou gerar um ranking (`ROW_NUMBER()`, `RANK()`) que reseta a contagem para cada categoria (usando `PARTITION BY`).

---

## 📚 Referência: Sintaxe e Exemplos

Antes de iniciar os desafios, consulte este guia rápido com exemplos das estruturas abordadas:

### 1. Subqueries (Subconsultas)
Uma subquery é uma consulta aninhada dentro de outra. Pode retornar um único valor (escalar) ou uma lista/tabela de valores.
```sql
-- Exemplo Escalar: Encontrar vagas que pagam mais que a média geral
SELECT titulo, salario 
FROM vaga 
WHERE salario > (SELECT AVG(salario) FROM vaga);
```

```sql
-- Exemplo Lista de Valores: Encontrar vagas publicadas por empresas de 'Tecnologia'
SELECT titulo, salario
FROM vaga
WHERE empresa_id IN (
    SELECT id 
    FROM empresa 
    WHERE setor = 'Tecnologia'
);
```

```sql
-- Exemplo Lista de Valores: Encontrar vagas de empresas do setor de Tecnologia
SELECT titulo, salario
FROM vaga
WHERE empresa_id IN (
    SELECT id 
    FROM empresa 
    WHERE setor = 'Tecnologia'
);
```

### 2. CTE - Common Table Expressions (Cláusula WITH)
As CTEs funcionam como tabelas temporárias que existem apenas durante a execução da consulta. Elas deixam o código muito mais legível que subqueries aninhadas (no FROM ou no WHERE).
```sql
-- Exemplo: Isolar uma lógica na CTE, e depois utilizá-la na consulta principal
WITH MediaSalarial AS (
    SELECT AVG(salario) as media_geral FROM vaga
)
SELECT titulo, salario 
FROM vaga, MediaSalarial
WHERE salario > media_geral;
```

### 3. Window Functions (Funções de Janela)
Diferente do `GROUP BY`, que colapsa (agrupa) várias linhas em uma só, as Window Functions executam cálculos em um conjunto de linhas ("janela") mas preservam o detalhe individual de cada linha na exibição.
```sql
-- Exemplo: Mostrar o salário da vaga e a média de salários apenas daquela empresa específica (PARTITION BY) na mesma linha
SELECT 
    titulo, 
    salario, 
    AVG(salario) OVER (PARTITION BY empresa_id) as media_da_empresa
FROM vaga;
```

---

## Problema
A diretoria da Plataforma de Recrutamento quer entender melhor os candidatos e os salários do mercado. Consultas simples (apenas com `JOIN` e `GROUP BY`) estão ficando difíceis de ler e dar manutenção. A regra de negócio exige relatórios sobre "Rankings" e análises inter-tabelas avançadas.

## Procedimento (Nível 1 - Execução)

A diretoria pediu um relatório classificando o status das vagas de uma forma mais legível (traduzida). Teste o código abaixo que utiliza a cláusula `CASE`:

```sql
SELECT 
    titulo, 
    salario,
    CASE 
        WHEN status = 'ABERTA' THEN 'Buscando Candidatos'
        WHEN status = 'PAUSADA' THEN 'Em espera'
        ELSE 'Processo Encerrado'
    END as status_traduzido
FROM vaga
LIMIT 10;
```

## Desafio (Nível 1.5) - Classificação e Agregação de Salários

O time de análise de mercado necessita de um relatório quantitativo sobre as faixas salariais oferecidas por cada **título de vaga** (especialidade).

**Regras de Negócio para Faixa Salarial:**
- **Alto:** Salário maior que 9.000
- **Médio:** Salário entre 4.000 e 9.000 (inclusive)
- **Baixo:** Salário menor que 4.000

**Questões:**

**a)** Escreva uma consulta utilizando a cláusula `CASE` que retorne a especialidade da vaga (`titulo`), o valor do `salario` e uma coluna calculada chamada `faixa_salarial` (Alto, Médio ou Baixo).

**b)** Modifique a consulta anterior utilizando `GROUP BY` para contabilizar quantas vagas existem em cada `faixa_salarial` por especialidade. 

**c)** Aplique um filtro (`WHERE`) na consulta da questão **b** para exibir os dados de apenas uma especialidade específica (por exemplo, 'Desenvolvedor Backend'). O resultado esperado deve conter até 3 linhas, representando a quantidade de vagas nas faixas Alto, Médio e Baixo para aquela especialidade.


## Exercício 1: Subqueries (Subconsultas)

A diretoria agora quer descobrir **"Quais candidatos se inscreveram em vagas que pagam MAIS que a média geral de todas as vagas do sistema?"**

Para isso, você precisa usar uma **Subquery**.
*Dica:* Calcule primeiro a média na subquery `(SELECT AVG(salario) FROM vaga)` e depois faça o SELECT cruzando as tabelas `candidato`, `candidatura` e `vaga`.

---

## Exercício 2: CTEs (Common Table Expressions)

Um analista de RH escreveu a seguinte consulta utilizando uma Subquery na cláusula `FROM` (também chamada de Tabela Derivada) para descobrir quais empresas têm mais de 5 vagas abertas:

```sql
SELECT nome_empresa, total_vagas 
FROM (
    SELECT e.nome as nome_empresa, COUNT(v.id) as total_vagas
    FROM empresa e
    JOIN vaga v ON e.id = v.empresa_id
    WHERE v.status = 'ABERTA'
    GROUP BY e.nome
) sub
WHERE total_vagas > 5;
```

**Desafio:**
Reescreva a consulta acima substituindo a Subquery aninhada por uma **CTE (cláusula WITH)**. O objetivo é provar como as CTEs melhoram a legibilidade do código separando a lógica de negócio da consulta principal.

---

## Exercício 3: O Ranking de Salários (Window Functions)

A equipe de Headhunters solicitou o seguinte relatório analítico:
Eles querem ver as vagas de **cada empresa**, mas desejam uma coluna extra mostrando qual é a **posição no ranking (1º, 2º, 3º...) daquela vaga** dentro da própria empresa, ordenado do maior salário para o menor.

**Requisitos:**
- Colunas: `nome_empresa`, `titulo_vaga`, `salario`, `posicao_ranking_na_empresa`
- Se você usar `GROUP BY`, você perderá o detalhe de cada vaga. Você **deve** usar Window Functions (`RANK()` ou `ROW_NUMBER()` com `PARTITION BY`).
- Se houver empate de salários, dê a eles o mesmo Rank.

Escreva a solução para todos os desafios e exercícios em um arquivo chamado `solucao.sql` e valide os resultados executando-as no seu banco de dados.

---
## Perguntas
- Qual é a principal diferença de performance e leitura entre usar múltiplas tabelas derivadas em subqueries no `FROM` versus utilizar `WITH` (CTEs)?
- Por que Window Functions são melhores do que `GROUP BY` quando precisamos mostrar tanto o valor individual da linha quanto o valor calculado do grupo na mesma tela?
