# Lista de Exercícios: SQL Progressivo 

Para facilitar a imersão, usaremos o **Sistema de Gestão Hospitalar** que já modelamos antes.

## 🛠️ O Esquema (Tabelas para o Exercício)
Aqui está o resumo das colunas que os alunos precisarão para as consultas:
- **`Paciente`** (ID_Paciente, CPF, Nome_Completo, Data_Nascimento)
- **`Medico`** (ID_Medico, CRM, UF_CRM, Nome_Medico)
- **`Especialidade`** (ID_Especialidade, Nome_Especialidade)
- **`Medico_Especialidade`** (ID_Medico, ID_Especialidade) *(Tabela Associativa N:M)*
- **`Consulta`** (ID_Consulta, ID_Paciente, ID_Medico, ID_Especialidade, Data_Hora_Inicio, Status)

---

## Nível 1: O Básico (Filtros e Ordenação)
*Foco do professor: Ensinar a estrutura SELECT, FROM, WHERE, uso do AND/OR e ORDER BY.*

*   **Ex 1.1:** Liste o nome completo e o CPF de todos os pacientes cadastrados, ordenados em ordem alfabética de Nome.
*   **Ex 1.2:** Busque o nome e o CRM de todos os médicos que atuam no estado de Minas Gerais (`UF_CRM = 'MG'`).
*   **Ex 1.3:** Liste todas as colunas das consultas que estão com o Status igual a 'Cancelada'.
*   **Ex 1.4:** Liste todos os médicos cujo nome começa com "Ana" (Dica: ensine o operador `LIKE`).
*   **Ex 1.5 (Desafio de Data):** Liste os pacientes que nasceram após o ano de 2000. *(Dica: o aluno pode extrair o ano `EXTRACT(YEAR FROM Data_Nascimento) > 2000` ou comparar diretamente com '2000-12-31').*

---

## Nível 2: Agrupamentos e Estatísticas
*Foco do professor: Funções de agregação (COUNT, SUM, MAX) e as cláusulas GROUP BY e HAVING.*

*   **Ex 2.1:** Quantos pacientes (contagem total) existem cadastrados no sistema?
*   **Ex 2.2:** Conte quantos médicos existem agrupados por Estado (UF). O resultado deve mostrar a `UF_CRM` e a quantidade.
*   **Ex 2.3:** Usando a tabela `Consulta`, conte quantas consultas existem para cada `Status` ('Realizada', 'Agendada', 'Cancelada').
*   **Ex 2.4:** Usando a query anterior (Ex 2.2), liste **apenas** os Estados (UFs) que possuem mais de 10 médicos cadastrados. *(Dica: Ensinar que o `WHERE` não funciona em agregações, deve-se usar `HAVING`).*
*   **Ex 2.5:** Mostre o total de consultas agrupadas pelo ano em que elas ocorreram (olhando para `Data_Hora_Inicio`).

---

## Nível 3: Conectando as Entidades (JOINs Simples)
*Foco do professor: A lógica do `INNER JOIN` ligando Chaves Primárias (PK) com Chaves Estrangeiras (FK).*

*   **Ex 3.1:** Mostrar códigos não diz nada ao usuário final. Faça um relatório mostrando a Data da Consulta, o Status, e o **Nome do Paciente** que realizou aquela consulta. *(Junção: Consulta + Paciente).*
*   **Ex 3.2:** Liste o **Nome do Médico** e a Data da consulta para todas as consultas com status 'Realizada'. *(Junção: Consulta + Medico).*
*   **Ex 3.3:** Liste os nomes de todos os Médicos juntamente com os `ID_Especialidade` que eles possuem cadastrados na tabela associativa. *(Junção: Medico + Medico_Especialidade).*

---

## Nível 4: JOINs Intermediários (Múltiplas Tabelas e LEFT JOIN)
*Foco do professor: Perder o medo de encadear JOINs e entender quando usar OUTER (LEFT) JOINs.*

*   **Ex 4.1 (3 Tabelas):** Chegou a hora de juntar tudo. Mostre o **Nome do Paciente**, a **Data da Consulta** e o **Nome do Médico** que o atendeu na mesma linha! *(Junção: Paciente + Consulta + Medico).*
*   **Ex 4.2 (O Poder do LEFT JOIN):** Liste o nome de TODOS os pacientes e as datas de suas consultas. Mas atenção à pegadinha do chefe: se um paciente acabou de se cadastrar e ainda **não tem** nenhuma consulta, o nome dele **deve aparecer** na lista mesmo assim (com a data vazia/nula).
*   **Ex 4.3 (Quebrando o N:M):** Crie o "Guia Médico" do hospital. Mostre o nome do Médico e o **Nome da Especialidade** que ele possui (por extenso). *(Junção: Medico + Medico_Especialidade + Especialidade).*

---

## Nível 5: O Chefe Final (JOINs + Agrupamentos + Subqueries)
*Foco do professor: Unir as agregações (Nível 2) com múltiplas tabelas (Nível 4) e lógicas de exclusão.*

*   **Ex 5.1 (Agrupamento sobre JOIN):** Quem é o médico que mais atende? Gere um relatório mostrando o **Nome do Médico** e a **quantidade total de consultas** que ele já realizou ou tem agendada.
*   **Ex 5.2 (Filtro, Agrupamento e JOIN):** Mostre o **Nome da Especialidade** e a quantidade de consultas que foram **realizadas** (status = 'Realizada') para cada uma dessas especialidades no ano passado.
*   **Ex 5.3 (O "Anti-Join" ou Subquery):** O hospital quer fazer uma campanha de marketing. Gere uma lista com os nomes dos pacientes que **nunca** tiveram uma consulta. *(O professor pode ensinar duas abordagens: `LEFT JOIN` com `WHERE ID_Consulta IS NULL`, ou usando `WHERE ID_Paciente NOT IN (SELECT...)`).*
*   **Ex 5.4 (Desafio MAX + Group By):** Para cada Paciente, queremos saber a data da sua **Última Consulta** (a mais recente). Se o paciente nunca consultou, ele não precisa aparecer. *(Dica: Use a função `MAX()` na data de início, ligue Paciente com Consulta e agrupe pelo Nome do Paciente).*
