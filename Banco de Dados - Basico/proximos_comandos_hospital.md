# Guia Didático: Próximos Comandos SQL após CREATE, ALTER e INSERT
**Contexto de Aplicação:** Sistema de Gestão Hospitalar Normalizado  
**Origem dos Dados:** [dados_hospital.csv](dados_hospital.csv)  
**Scripts Prévios:** `create_tabelas_hospital.sql`, `alter_tabelas_relacionamentos.sql`, `insert_dados.sql`

---

## 📌 Visão Geral e Progressão Pedagógica

Nas etapas anteriores, a turma saiu de uma estrutura desnormalizada e propensa a anomalias ([dados_hospital.csv](dados_hospital.csv)) e executou os comandos fundamentais de definição e carga:
1. **`CREATE TABLE` (DDL):** Criou as tabelas normalizadas (1FN, 2FN e 3FN).
2. **`ALTER TABLE` (DDL):** Adicionou restrições de integridade, chaves estrangeiras (`FK`) e unicidade (`UNIQUE`).
3. **`INSERT INTO` (DML):** Povoou as tabelas com os registros do hospital.

Agora, os alunos devem avançar para o ciclo de **manipulação, consulta e reconstrução relacional** dos dados. A ordem pedagógica recomendada é:

```
[SELECT básico + WHERE + ORDER BY] ➔ [UPDATE e DELETE (com foco em integridade)] ➔ [JOINs (Reconstrução da planilha)] ➔ [GROUP BY e Agregações]
```

---

## 1. DQL: `SELECT` (Consultas, Filtros e Ordenação)

> **Objetivo didático:** Capacitar o aluno a extrair informações pontuais das tabelas isoladas sem depender de interfaces gráficas.

### 1.1. Projeção e Filtros Simples (`WHERE`)
```sql
-- 1. Listar apenas Nome e CPF dos pacientes cadastrados
SELECT Nome_Completo, CPF 
FROM Paciente;

-- 2. Filtrar consultas por status (ex: consultas canceladas ou com ausência)
SELECT ID_Consulta, Data_Hora_Inicio, Status 
FROM Consulta 
WHERE Status IN ('Cancelada', 'Paciente Faltou');

-- 3. Identificar médicos atuantes em um estado específico
SELECT CRM, Nome_Medico 
FROM Medico 
WHERE UF_CRM = 'SP';
```

### 1.2. Operadores de Busca Textual (`LIKE` / `ILIKE`)
```sql
-- 4. Buscar pacientes com histórico de alergia a antibióticos ou penicilina
SELECT ID_Paciente, Descricao 
FROM Paciente_Alergia 
WHERE Descricao ILIKE '%Penicilina%';

-- 5. Localizar médicos com nome iniciado por "Dr. Carlos"
SELECT CRM, UF_CRM, Nome_Medico 
FROM Medico 
WHERE Nome_Medico LIKE 'Dr. Carlos%';
```

### 1.3. Ordenação (`ORDER BY`) e Limitação (`LIMIT`)
```sql
-- 6. Listar os 3 procedimentos com maior valor base no hospital
SELECT Nome_Procedimento, Valor_Base 
FROM Procedimento 
ORDER BY Valor_Base DESC 
LIMIT 3;

-- 7. Listar a agenda de consultas por ordem cronológica
SELECT ID_Consulta, Data_Hora_Inicio, Status 
FROM Consulta 
ORDER BY Data_Hora_Inicio ASC;
```

---

## 2. DML: `UPDATE` (Atualização de Dados)

> **Objetivo didático:** Demonstrar a modificação de linhas existentes e alertar contra o erro clássico de alterar registros acidentalmente.

### 2.1. Alteração Pontual de Status
```sql
-- Simulação clínica: A consulta 1005 que estava pendente foi cancelada
UPDATE Consulta 
SET Status = 'Cancelada' 
WHERE ID_Consulta = 1005;
```

### 2.2. Atualização com Cálculos / Reajustes
```sql
-- Reajuste inflacionário de 10% no valor do Eletrocardiograma
UPDATE Procedimento 
SET Valor_Base = ROUND(Valor_Base * 1.10, 2) 
WHERE Codigo_TUSS = '10101012';
```

### 2.3. Atualização de Dados Cadastrais
```sql
-- Paciente alterou o número de telefone de contato
UPDATE Paciente_Telefone 
SET Numero = '(11) 98888-7777' 
WHERE ID_Paciente = 1 AND ID_Telefone = 1;
```

> ⚠️ **Alerta do Professor:** Sempre enfatizar que rodar `UPDATE Consulta SET Status = 'Cancelada';` sem a cláusula `WHERE` cancelará **todas** as consultas do hospital. Incentive os alunos a executarem um `SELECT` com o mesmo `WHERE` antes de aplicar o `UPDATE`.

---

## 3. DML: `DELETE` e Restrições de Integridade

> **Objetivo didático:** Ensinar a exclusão segura e demonstrar o funcionamento real das Chaves Estrangeiras (`FOREIGN KEY`) bloqueando exclusões indevidas.

### 3.1. Exclusão Pontual Permitida
```sql
-- Paciente solicitou a remoção de um telefone secundário
DELETE FROM Paciente_Telefone 
WHERE ID_Telefone = 2;
```

### 3.2. Teste Prático de Violação de Chave Estrangeira (Erro Didático)
Peça para os alunos executarem o comando abaixo:
```sql
-- Tentativa de apagar diretamente o paciente ID 1
DELETE FROM Paciente 
WHERE ID_Paciente = 1;
```
* **Comportamento esperado do SGBD:** O PostgreSQL abortará o comando com mensagem de violação de integridade referencial (`violates foreign key constraint`).
* **Conceito ensinado:** Uma linha pai não pode ser excluída enquanto existirem linhas dependentes em `Consulta`, `Paciente_Alergia` ou `Paciente_Telefone`.

### 3.3. Tabela Comparativa: DELETE vs TRUNCATE vs DROP

| Comando | Tipo | Ação | Recuperável (Rollback)? | Reseta Sequences / Serial? |
| :--- | :--- | :--- | :--- | :--- |
| `DELETE FROM Tabela WHERE ...` | DML | Remove linhas selecionadas | Sim | Não |
| `TRUNCATE TABLE Tabela` | DDL | Esvazia a tabela rapidamente | Sim (em transação Postgres) | Sim (`RESTART IDENTITY`) |
| `DROP TABLE Tabela` | DDL | Destrói a tabela e seus metadados | Sim (em transação Postgres) | O objeto deixa de existir |

---

## 4. DQL Avançado: `JOIN` (Reconstruindo a Planilha Original)

> **Momento-chave da disciplina:** Quando os alunos normalizaram o CSV, separaram os dados em mais de 10 tabelas. O `JOIN` é o comando que fecha o raciocínio, permitindo cruzar as tabelas para exibir a informação consolidada como na planilha original, mas mantendo a integridade relacional.

### 4.1. `INNER JOIN` – Reconstrução da Ficha de Consulta
```sql
SELECT 
    c.ID_Consulta,
    c.Data_Hora_Inicio,
    p.Nome_Completo AS Nome_Paciente,
    p.CPF AS CPF_Paciente,
    m.Nome_Medico,
    m.CRM || '/' || m.UF_CRM AS Registro_Medico,
    s.Numero_Sala,
    c.Status
FROM Consulta c
INNER JOIN Paciente p ON c.ID_Paciente = p.ID_Paciente
INNER JOIN Medico m   ON c.ID_Medico = m.ID_Medico
INNER JOIN Sala s     ON c.ID_Sala = s.ID_Sala
ORDER BY c.Data_Hora_Inicio;
```

### 4.2. `LEFT JOIN` – Identificação de Casos Nulos
```sql
-- Listar todos os médicos e as consultas associadas, exibindo médicos sem consultas agendadas
SELECT 
    m.Nome_Medico,
    m.CRM,
    c.ID_Consulta,
    c.Data_Hora_Inicio
FROM Medico m
LEFT JOIN Consulta c ON m.ID_Medico = c.ID_Medico;
```

---

## 5. DQL Analítico: Funções de Agregação e `GROUP BY`

> **Objetivo didático:** Responder a relatórios gerenciais e estatísticas do hospital.

### 5.1. Contagens e Agrupamentos Básicos
```sql
-- Total de consultas por Status
SELECT Status, COUNT(*) AS Total_Consultas 
FROM Consulta 
GROUP BY Status;

-- Total de médicos por Estado
SELECT UF_CRM, COUNT(*) AS Quantidade_Medicos 
FROM Medico 
GROUP BY UF_CRM 
ORDER BY Quantidade_Medicos DESC;
```

### 5.2. Filtros em Agrupamentos com `HAVING`
```sql
-- Especialidades com mais de 1 médico cadastrado
SELECT me.ID_Especialidade, e.Nome_Especialidade, COUNT(*) AS Qtd_Medicos
FROM Medico_Especialidade me
INNER JOIN Especialidade e ON me.ID_Especialidade = e.ID_Especialidade
GROUP BY me.ID_Especialidade, e.Nome_Especialidade
HAVING COUNT(*) > 1;
```

---

## 📋 Roteiro de Aplicação em Aulas

1. **Aula 1 – DQL Fundamental:**
   * Prática com `SELECT`, colunas pontuais, `WHERE`, operadores de comparação e `LIKE`.
   * Exercício: "Localize na base os pacientes que relataram alergia alimentar".
2. **Aula 2 – DML Seguro e Integridade:**
   * Prática com `UPDATE` e `DELETE`.
   * Simulação proposital de erro com `DELETE` em chave pai com filhos vinculados.
3. **Aula 3 – Junções de Tabelas (`JOIN`):**
   * Remontar o relatório original do [dados_hospital.csv](dados_hospital.csv) combinando `Consulta`, `Paciente`, `Medico`, `Convenio` e `Sala`.
4. **Aula 4 – Agregações Gerenciais:**
   * Prática com `COUNT`, `SUM`, `AVG`, `GROUP BY` e `HAVING`.
