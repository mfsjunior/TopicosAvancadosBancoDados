# Aula 05: DQL e DML – Consultas Filtradas, Atualizações e Exclusão Segura

**Contexto:** Exploração inicial do banco de dados hospitalar normalizado através de consultas e manipulações pontuais.  
**Tabelas Principais:** `Paciente`, `Medico`, `Consulta`, `Procedimento`, `Paciente_Alergia`, `Paciente_Telefone`, `Prescricao`.  
**Script de Inicialização:** [dump_hospital_completo.sql](dump_hospital_completo.sql)

---

## 🎯 Objetivos da Aula
1. Dominar a cláusula `SELECT` com projeção específica de colunas e uso de apelidos (`AS`).
2. Filtrar dados com precisão usando `WHERE`, operadores relacionais (`=`, `<>`, `>`, `<`, `BETWEEN`, `IN`, `IS NULL`) e lógicos (`AND`, `OR`, `NOT`).
3. Realizar buscas textuais flexíveis com `LIKE` e `ILIKE` utilizando os curingas `%` e `_`.
4. Executar atualizações (`UPDATE`) e exclusões (`DELETE`) com segurança, entendendo as consequências do esquecimento da cláusula `WHERE`.
5. Compreender e disparar na prática erros de violação de integridade referencial por Chave Estrangeira (`FOREIGN KEY`).

---

## 1. DQL: Consultando e Filtrando Dados (`SELECT`)

### 1.1. Projeção Seletiva e Apelidos (`AS`)
Evite usar `SELECT *` em produção. Projete apenas as colunas necessárias para economizar tráfego de rede e memória:

```sql
SELECT 
    Nome_Completo AS Paciente, 
    CPF, 
    Data_Nascimento AS "Data de Nascimento"
FROM Paciente;
```

### 1.2. Filtros Condicionais com `WHERE`
```sql
-- Consultas que não foram concluídas (canceladas ou falta do paciente)
SELECT ID_Consulta, Data_Hora_Inicio, Status 
FROM Consulta 
WHERE Status IN ('Cancelada', 'Paciente Faltou');

-- Médicos que atuam fora do estado de São Paulo
SELECT CRM, UF_CRM, Nome_Medico 
FROM Medico 
WHERE UF_CRM <> 'SP';

-- Procedimentos com valor entre R$ 100,00 e R$ 250,00
SELECT Codigo_TUSS, Nome_Procedimento, Valor_Base 
FROM Procedimento 
WHERE Valor_Base BETWEEN 100.00 AND 250.00;
```

### 1.3. Busca por Padrões de Texto (`LIKE` e `ILIKE`)
* `%` substitui zero ou múltiplos caracteres.
* `_` substitui exatamente um caractere.
* `ILIKE` é específico do PostgreSQL (insensível a maiúsculas/minúsculas).

```sql
-- Buscar qualquer paciente que tenha alergia relacionada a pó ou poeira
SELECT ID_Paciente, Descricao 
FROM Paciente_Alergia 
WHERE Descricao ILIKE '%poeira%';

-- Médicos cujo nome começa com "Dr. Carlos"
SELECT Nome_Medico, CRM, UF_CRM 
FROM Medico 
WHERE Nome_Medico LIKE 'Dr. Carlos%';
```

### 1.4. Ordenação (`ORDER BY`) e Paginação (`LIMIT` e `OFFSET`)

Em sistemas reais (como o prontuário eletrônico do hospital), uma tabela pode ter centenas de milhares de linhas. Trazer tudo de uma vez trava a tela do usuário e sobrecarrega a rede. Por isso, as aplicações utilizam **Paginação**:

* **`LIMIT N`:** Quantidade máxima de linhas que serão devolvidas (o tamanho da página).
* **`OFFSET M`:** Quantidade de linhas que o banco deve **pular** antes de começar a entregar os dados.

#### 🧮 A Fórmula da Paginação:
Para exibir a **Página $P$** trazendo **$N$ registros por página**:
$$\text{OFFSET} = (P - 1) \times N$$

---

#### 💻 Exemplos Práticos: Navegando no Cadastro de Pacientes (2 por página)

```sql
-- PÁGINA 1: Mostra os 2 primeiros pacientes (pula 0)
SELECT ID_Paciente, Nome_Completo, CPF 
FROM Paciente 
ORDER BY ID_Paciente ASC 
LIMIT 2 OFFSET 0;

-- PÁGINA 2: Mostra os próximos 2 pacientes (pula 2)
SELECT ID_Paciente, Nome_Completo, CPF 
FROM Paciente 
ORDER BY ID_Paciente ASC 
LIMIT 2 OFFSET 2;

-- PÁGINA 3: Mostra os próximos 2 pacientes (pula 4)
SELECT ID_Paciente, Nome_Completo, CPF 
FROM Paciente 
ORDER BY ID_Paciente ASC 
LIMIT 2 OFFSET 4;
```

#### Outro Caso de Uso: Top N (Ranking)
```sql
-- Top 3 procedimentos mais caros cadastrados no hospital
SELECT Nome_Procedimento, Valor_Base 
FROM Procedimento 
ORDER BY Valor_Base DESC 
LIMIT 3;
```

> ⚠️ **A REGRA DE OURO DA PAGINAÇÃO:**  
> **Nunca use `LIMIT` e `OFFSET` sem `ORDER BY`!** Se você não definir uma ordem explícita (como por chave primária ou data), o SGBD não garante a ordem física das linhas, e o mesmo paciente pode aparecer na página 1 e na página 2 ao mesmo tempo.

---

## 2. DML: Atualização Controlada (`UPDATE`)

O comando `UPDATE` modifica registros já persistidos no banco.

### 2.1. Anatomia do Comando
```sql
UPDATE Nome_Tabela
SET Coluna1 = Novo_Valor1, Coluna2 = Novo_Valor2
WHERE Condicao_Exata;
```

### 2.2. Casos Práticos do Hospital
```sql
-- 1. O paciente informou que mudou de telefone
UPDATE Paciente_Telefone 
SET Numero = '(11) 97777-6666' 
WHERE ID_Paciente = 1 AND ID_Telefone = 1;

-- 2. A consulta 1005 foi cancelada pelo paciente por telefone
UPDATE Consulta 
SET Status = 'Cancelada' 
WHERE ID_Consulta = 1005;

-- 3. Reajuste de 15% na tabela de preços para exames clínicos
UPDATE Procedimento 
SET Valor_Base = ROUND(Valor_Base * 1.15, 2) 
WHERE Nome_Procedimento ILIKE '%Exame Clínico%';
```

> ⚠️ **A REGRA DE OURO:**  
> Jamais execute um `UPDATE` sem antes rodar um `SELECT` com a mesmíssima cláusula `WHERE` para auditar quais linhas serão impactadas.

---

## 3. DML: Exclusão Segura e Integridade (`DELETE`)

O comando `DELETE` remove linhas inteiras de uma tabela.

### 3.1. Exclusão Específica
```sql
-- Paciente solicitou a remoção de um telefone secundário
DELETE FROM Paciente_Telefone 
WHERE ID_Telefone = 2;
```

### 3.2. A Trava da Foreign Key (Experimento de Aula)
Rodem no banco:
```sql
DELETE FROM Paciente WHERE ID_Paciente = 1;
```
* **O que acontece?** O PostgreSQL bloqueia a operação emitindo:
  `ERROR: update or delete on table "paciente" violates foreign key constraint on table "consulta"`
* **Explicação teórica:** O banco protege o histórico. Se o paciente fosse apagado, as consultas, receitas e registros do prontuário se tornariam "órfãos" sem dono.

### 3.3. DELETE vs TRUNCATE vs DROP
* **`DELETE FROM Tabela WHERE ...`:** Exclui linha por linha, avalia triggers e mantém as sequências (`SERIAL`).
* **`TRUNCATE TABLE Tabela;`:** DDL de limpeza ultrarrápida. Esvazia todos os registros e pode resetar sequências (`RESTART IDENTITY`).
* **`DROP TABLE Tabela;`:** DDL de destruição. Apaga dados, índices, constraints e a própria definição da tabela.

---

# 🏥 ESTUDO DE CASO PRÁTICO: PLANTÃO DE TI NO HOSPITAL SANTA CLARA

> **Instruções ao Aluno:**  
> Você foi escalado como **Analista de Banco de Dados** responsável pelo plantão de sustentação do Hospital Geral Santa Clara. O sistema legado acabou de ser restaurado via `dump_hospital_completo.sql`.  
> A diretoria clínica, o corpo de enfermagem e o setor de faturamento enviaram uma lista urgente de demandas operacionais.  
> **Você deverá construir os códigos SQL correspondentes a cada solicitação** e justificar tecnicamente as decisões de integridade e segurança adotadas.

---

## PARTE 1: Auditoria Clínica e Triagem de Pacientes (DQL - SELECT Avançado)

### Questão 1: Triagem de Pacientes em Faixa de Risco
O comitê de infectologia do hospital precisa identificar pacientes pertencentes ao grupo de risco com base em sua faixa etária.  
* **O que você deverá fazer:** Escreva uma consulta SQL que retorne o `ID_Paciente`, o `Nome_Completo`, o `CPF` e a `Data_Nascimento` de todos os pacientes que nasceram **antes de 01/01/1980** OU **após 31/12/2000**. Os resultados devem ser ordenados de forma decrescente pela `Data_Nascimento` (do mais jovem ao mais idoso).

### Questão 2: Protocolo Preventivo de Alergias Medicamentosas
Um paciente deu entrada desacordado na emergência e o corpo médico precisa checar o banco de dados contra riscos de choque anafilático.  
* **O que você deverá fazer:** Escreva uma consulta SQL que retorne o `ID_Paciente` e a `Descricao` da alergia na tabela `Paciente_Alergia` para qualquer registro que mencione alergias a **Penicilina**, **Dipirona** ou **Lactose**. Sua busca deve ser insensível a maiúsculas/minúsculas (`ILIKE`) e utilizar o operador curinga `%` de forma correta.

### Questão 3: Rastreabilidade Financeira e Tabela de Procedimentos
O setor financeiro solicitou uma auditoria dos procedimentos médicos cadastrados para planejar o orçamento anual.  
* **O que você deverá fazer:** Construa uma consulta que selecione o `Codigo_TUSS`, o `Nome_Procedimento` e o `Valor_Base` de todos os procedimentos cujo valor esteja no intervalo entre **R$ 70,00 e R$ 200,00** (inclusive), excluindo procedimentos que custem exatamente R$ 150,00. Ordene o resultado pelo `Valor_Base` em ordem crescente.

### Questão 4: Auditoria de Agendamentos e Pacientes Sem Convênio
A recepção precisa mapear as consultas que ocorreram sem cobertura de convênio médico (atendimentos particulares).  
* **O que você deverá fazer:** Escreva uma consulta na tabela `Consulta` que exiba o `ID_Consulta`, `Data_Hora_Inicio`, `ID_Medico` e `Status`, filtrando apenas as consultas em que o campo `ID_Paciente_Convenio` seja nulo (`IS NULL`) E cujo status seja `'Agendada'` ou `'Realizada'`.

---

## PARTE 2: Gestão de Crise e Modificações Operacionais (DML - UPDATE Seguro)

### Questão 5: Protocolo de Atualização Segura de Contatos
O paciente `João da Silva` (ID 1) compareceu à recepção e solicitou a atualização do seu telefone celular principal.  
* **O que você deverá fazer:**  
  1. Escreva primeiro o comando `SELECT` que você executaria para inspecionar os telefones atuais do paciente `ID_Paciente = 1`.  
  2. Em seguida, escreva o comando `UPDATE` que altera o telefone `ID_Telefone = 1` para o novo número `'(11) 91111-2222'`.  
  3. Explique por que é uma falha gravíssima executar o comando sem especificar simultaneamente `ID_Telefone` e `ID_Paciente`.

### Questão 6: Afastamento Médico de Emergência e Cancelamento em Lote
O médico `Dr. Roberto Costa` (ID 1) sofreu uma emergência médica particular e precisou se ausentar do hospital por 15 dias. Todas as consultas dele que ainda estavam com status `'Agendada'` devem ser imediatamente alteradas para `'Cancelada'`. Consultas já `'Realizadas'` no passado não podem ser alteradas.  
* **O que você deverá fazer:**  
  1. Escreva o `SELECT` prévio de auditoria para contar quantas consultas serão afetadas.  
  2. Escreva o comando `UPDATE` cirúrgico na tabela `Consulta` que altera o `Status` para `'Cancelada'` apenas para o médico `ID_Medico = 1` e cujas consultas estejam com status `'Agendada'`.

### Questão 7: Reajuste Inflacionário Seletivo na Tabela de Procedimentos
A diretoria autorizou um reajuste de preços:  
* Procedimentos com valor base inferior a R$ 100,00 sofrerão reajuste de **12%**.  
* **O que você deverá fazer:** Escreva o comando `UPDATE` que aplica esse reajuste de 12% na tabela `Procedimento`, arredondando o resultado para duas casas decimais com a função `ROUND(..., 2)`. O reajuste deve atingir estritamente os procedimentos com `Valor_Base < 100.00`.

---

## PARTE 3: Saneamento Cadastral e Integridade Referencial (DML - DELETE)

### Questão 8: Remoção Pontual de Linhas Dependentes
A paciente `Maria Oliveira` (ID 2) informou que não possui mais o telefone fixo cadastrado com código `ID_Telefone = 3`.  
* **O que você deverá fazer:** Escreva o comando `DELETE` para remover exclusivamente esse número da tabela `Paciente_Telefone`, garantindo que o outro telefone da paciente permaneça intacto.

### Questão 9: O Teste de Fogo da Chave Estrangeira (Simulação de Erro)
Um atendente novato tentou apagar o registro do médico `Dr. Roberto Costa` rodando o comando:  
`DELETE FROM Medico WHERE ID_Medico = 1;`  
* **O que você deverá fazer:**  
  1. Execute esse comando no seu banco de dados e anote a mensagem de erro exata retornada pelo PostgreSQL.  
  2. Explique tecnicamente por que o banco de dados recusou a execução do comando.  
  3. Caso a diretoria exigisse a remoção completa e manual desse médico sem usar `CASCADE` automático, liste em qual **ordem exata** de tabelas você precisaria deletar os dados para não violar as Chaves Estrangeiras.

---

## PARTE 4: Teoria Aplicada e Resposta a Incidentes de Banco de Dados

### Questão 10: O Comportamento das Sequências (`SERIAL` / `AUTO_INCREMENT`)
Suponha que você execute os três comandos abaixo em sequência:
```sql
INSERT INTO Medicamento (Nome_Medicamento) VALUES ('Medicamento Fantasma'); -- Suponha que recebeu ID 5
DELETE FROM Medicamento WHERE ID_Medicamento = 5;
INSERT INTO Medicamento (Nome_Medicamento) VALUES ('Novo Medicamento');
```
* **O que você deverá responder:**  
  Qual será o `ID_Medicamento` atribuído ao `'Novo Medicamento'`? Ele reutilizará o ID 5 ou receberá o ID 6? Justifique com base no funcionamento dos objetos `SEQUENCE` nativos dos bancos de dados relacionais e no risco de reutilização de chaves primárias.

### Questão 11: Análise de Desastre – O UPDATE sem WHERE
Um estagiário rodou acidentalmente na base de produção o seguinte comando:
```sql
UPDATE Consulta SET Status = 'Cancelada';
```
* **O que você deverá responder:**  
  1. Qual é o impacto imediato dessa instrução na operação do hospital?  
  2. Se a sessão estivesse rodando dentro de um bloco transacional iniciado com `BEGIN;`, qual comando salvaria o banco de dados da destruição antes do `COMMIT;`?  
  3. Por que ferramentas como DBeaver e pgAdmin possuem opções de configuração chamadas *"Safe Updates"* ou *"Confirm non-keyed updates"*?

---

# 📖 GABARITO E RESPOSTAS ESPERADAS (AUTOAVALIAÇÃO)

### Resolução Questão 1:
```sql
SELECT ID_Paciente, Nome_Completo, CPF, Data_Nascimento
FROM Paciente
WHERE Data_Nascimento < '1980-01-01' OR Data_Nascimento > '2000-12-31'
ORDER BY Data_Nascimento DESC;
```

### Resolução Questão 2:
```sql
SELECT ID_Paciente, Descricao
FROM Paciente_Alergia
WHERE Descricao ILIKE '%Penicilina%'
   OR Descricao ILIKE '%Dipirona%'
   OR Descricao ILIKE '%Lactose%';
```

### Resolução Questão 3:
```sql
SELECT Codigo_TUSS, Nome_Procedimento, Valor_Base
FROM Procedimento
WHERE Valor_Base BETWEEN 70.00 AND 200.00
  AND Valor_Base <> 150.00
ORDER BY Valor_Base ASC;
```

### Resolução Questão 4:
```sql
SELECT ID_Consulta, Data_Hora_Inicio, ID_Medico, Status
FROM Consulta
WHERE ID_Paciente_Convenio IS NULL
  AND Status IN ('Agendada', 'Realizada');
```

### Resolução Questão 5:
```sql
-- 1. Auditoria prévia
SELECT * FROM Paciente_Telefone WHERE ID_Paciente = 1;

-- 2. Atualização cirúrgica
UPDATE Paciente_Telefone
SET Numero = '(11) 91111-2222'
WHERE ID_Telefone = 1 AND ID_Paciente = 1;
```
* **Justificativa:** Se omitir o `ID_Telefone`, o comando atualizaria todos os telefones do João para o mesmo número celular. Se omitir o `ID_Paciente`, correria o risco de alterar o telefone de outro paciente caso o `ID_Telefone` estivesse errado.

### Resolução Questão 6:
```sql
-- 1. Contagem/Auditoria
SELECT COUNT(*) FROM Consulta WHERE ID_Medico = 1 AND Status = 'Agendada';

-- 2. Update direcionado
UPDATE Consulta
SET Status = 'Cancelada'
WHERE ID_Medico = 1 AND Status = 'Agendada';
```

### Resolução Questão 7:
```sql
UPDATE Procedimento
SET Valor_Base = ROUND(Valor_Base * 1.12, 2)
WHERE Valor_Base < 100.00;
```

### Resolução Questão 8:
```sql
DELETE FROM Paciente_Telefone
WHERE ID_Telefone = 3;
```

### Resolução Questão 9:
1. **Erro retornado:** `ERROR: update or delete on table "medico" violates foreign key constraint "fk_consulta_medico" on table "consulta"`.
2. **Motivo técnico:** O médico possui chave primária referenciada na tabela `Consulta` (e possivelmente na associativa `Medico_Especialidade`). O banco protege a integridade referencial impedindo consultas órfãs.
3. **Ordem de exclusão manual obrigatória:**
   - 1º: Apagar as receitas do médico (`Prescricao`) vinculadas às consultas dele.
   - 2º: Apagar os procedimentos realizados nas consultas dele (`Consulta_Procedimento`).
   - 3º: Apagar as consultas do médico (`Consulta`).
   - 4º: Apagar os vínculos na tabela associativa (`Medico_Especialidade`).
   - 5º: Apagar finalmente o registro em `Medico`.

### Resolução Questão 10:
* O novo medicamento receberá o **ID 6**.
* **Justificativa:** Objetivos do tipo `SEQUENCE` são não-transacionais e estritamente monotônicos crescentes. Quando um número da sequência é consumido pelo `nextval()`, ele nunca volta atrás, mesmo se a transação for abortada ou se o registro for deletado. Isso impede colisões de chaves e anomalias de concorrência em sistemas multiusuário.

### Resolução Questão 11:
1. **Impacto:** Todas as consultas do hospital (inclusive as já realizadas há anos e as faturadas) seriam alteradas para canceladas, inviabilizando prontuários e gerando caos contábil.
2. **Comando salvador:** `ROLLBACK;`.
3. **Safe Updates:** Essa funcionalidade exige obrigatoriamente que qualquer `UPDATE` ou `DELETE` utilize uma chave primária na cláusula `WHERE`, impedindo que comandos sem filtro ou com filtros genéricos modifiquem a tabela inteira por engano.
