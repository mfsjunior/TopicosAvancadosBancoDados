# Aula 07: DQL Analítico – Agregações, Métricas e Relatórios Gerenciais

**Contexto:** Transformar registros brutos do banco hospitalar em inteligência gerencial e indicadores estatísticos de saúde.  
**Tabelas Principais:** `Consulta`, `Procedimento`, `Medico`, `Paciente`, `Convenio`.

---

## 🎯 Objetivos da Aula
1. Compreender o propósito das Funções de Agregação (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`).
2. Dominar a cláusula `GROUP BY` e a regra de ouro das colunas projetadas no `SELECT`.
3. Diferenciar definitivamente o filtro de linhas brutas (`WHERE`) do filtro de grupos agregados (`HAVING`).
4. Cruzar tabelas com `JOIN` e sumarizar dados para responder a perguntas de negócio da diretoria do hospital.

---

## 1. Funções de Agregação Básicas

As funções de agregação realizam cálculos matemáticos sobre um conjunto de linhas e retornam um único valor sumarizado.

### 1.1. Principais Funções
```sql
-- 1. Contagem total de pacientes cadastrados
SELECT COUNT(*) AS Total_Pacientes 
FROM Paciente;

-- 2. Diferença didática: COUNT(*) vs COUNT(Coluna)
-- COUNT(coluna) ignora valores NULL!
SELECT 
    COUNT(*) AS Total_Consultas,
    COUNT(ID_Paciente_Convenio) AS Consultas_Com_Convenio
FROM Consulta;

-- 3. Métricas de valores de procedimentos do hospital
SELECT 
    MIN(Valor_Base) AS Procedimento_Mais_Barato,
    MAX(Valor_Base) AS Procedimento_Mais_Caro,
    ROUND(AVG(Valor_Base), 2) AS Ticket_Medio_Procedimentos,
    SUM(Valor_Base) AS Faturamento_Potencial_Catalogo
FROM Procedimento;
```

---

## 2. Agrupamentos com `GROUP BY`

O `GROUP BY` condensa linhas com valores idênticos em colunas específicas para produzir métricas segmentadas por categoria.

> ⚠️ **A Regra Mandatória do GROUP BY:**  
> Se você usou uma coluna no `SELECT` e ela **não** está dentro de uma função de agregação (`COUNT`, `SUM`, etc.), ela **obrigatoriamente deve constar** na cláusula `GROUP BY`.

### 2.1. Exemplos Práticos
```sql
-- Total de consultas distribuídas por Status
SELECT Status, COUNT(*) AS Quantidade
FROM Consulta
GROUP BY Status;

-- Total de médicos por Estado (UF)
SELECT UF_CRM, COUNT(*) AS Total_Medicos
FROM Medico
GROUP BY UF_CRM
ORDER BY Total_Medicos DESC;
```

---

## 3. Filtrando Agrupamentos: `WHERE` vs `HAVING`

Este é um dos pontos conceituais mais cobrados em concursos e entrevistas técnicas:

* **`WHERE`:** Executado **ANTES** da agregação. Filtra as linhas individuais do banco de dados antes de calcular as somas e contagens.
* **`HAVING`:** Executado **DEPOIS** da agregação. Filtra os grupos consolidados com base no resultado da função agregada.

```mermaid
flowchart LR
    TABELA[Tabela Bruta] -->|1. WHERE filtra linhas| FILTRADO[Linhas Válidas]
    FILTRADO -->|2. GROUP BY condensa| GRUPOS[Grupos Agrupados]
    GRUPOS -->|3. HAVING filtra grupos| RESULTADO[Resultado Final]
```

### 3.1. Exemplo Prático de Comparação
```sql
-- Mostrar apenas os estados que possuem MAIS DE 1 médico cadastrado
SELECT UF_CRM, COUNT(*) AS Total_Medicos
FROM Medico
GROUP BY UF_CRM
HAVING COUNT(*) > 1;

-- Combinando WHERE e HAVING:
-- Contar consultas Realizadas por médico, listando apenas médicos com mais de 2 consultas
SELECT ID_Medico, COUNT(*) AS Qtd_Realizadas
FROM Consulta
WHERE Status = 'Realizada'      -- 1. Filtra antes de agrupar
GROUP BY ID_Medico              -- 2. Agrupa por médico
HAVING COUNT(*) >= 2;           -- 3. Filtra o resultado da contagem
```

---

## 4. O Poder Completo: `JOIN` + `GROUP BY`

Aqui unimos a reconstrução relacional com a análise de métricas gerenciais para a diretoria do hospital.

### 4.1. Faturamento Total Gerado por Médico
```sql
SELECT 
    m.Nome_Medico,
    m.CRM || '/' || m.UF_CRM AS Registro_CRM,
    COUNT(c.ID_Consulta) AS Total_Atendimentos,
    COALESCE(SUM(p.Valor_Base), 0.00) AS Faturamento_Total
FROM Medico m
INNER JOIN Consulta c              ON m.ID_Medico = c.ID_Medico
INNER JOIN Consulta_Procedimento cp ON c.ID_Consulta = cp.ID_Consulta
INNER JOIN Procedimento p          ON cp.ID_Procedimento = p.ID_Procedimento
WHERE c.Status = 'Realizada'
GROUP BY m.ID_Medico, m.Nome_Medico, m.CRM, m.UF_CRM
ORDER BY Faturamento_Total DESC;
```

### 4.2. Quantidade de Consultas por Convênio
```sql
SELECT 
    conv.Nome_Operadora AS Operadora_Convenio,
    COUNT(c.ID_Consulta) AS Quantidade_Consultas
FROM Consulta c
INNER JOIN Paciente_Convenio pc ON c.ID_Paciente_Convenio = pc.ID_Paciente_Convenio
INNER JOIN Convenio conv        ON pc.ID_Convenio = conv.ID_Convenio
GROUP BY conv.ID_Convenio, conv.Nome_Operadora
ORDER BY Quantidade_Consultas DESC;
```

---

## 🏋️ Exercícios Práticos da Aula 07

1. **(Métrica Simples):** Calcule a média de duração em minutos (`Duracao_Minutos`) das consultas realizadas no hospital.
2. **(Agrupamento por Sala):** Descubra quantas consultas foram realizadas em cada sala (`Numero_Sala`).
3. **(Filtro de Grupo - HAVING):** Mostre as operadoras de convênio que tiveram mais de 2 atendimentos registrados na base.
4. **(Relatório Analítico Completo):** Gere um relatório listando o nome da especialidade e a quantidade de médicos vinculados a ela (`Especialidade` + `Medico_Especialidade`), ordenando da especialidade com mais médicos para a com menos médicos.
5. **(Desafio ):** Descubra qual paciente mais gastou em procedimentos no hospital até hoje.
