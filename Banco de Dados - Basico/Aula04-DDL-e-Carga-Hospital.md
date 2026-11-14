# Aula 04: DDL e Carga de Dados – Implementando o Modelo Hospitalar Normalizado

**Contexto:** Transição da planilha não-normalizada ([dados_hospital.csv](dados_hospital.csv)) para o banco relacional estruturado no PostgreSQL.  
**Arquivos de Apoio:** [create_tabelas_hospital.sql](create_tabelas_hospital.sql), [alter_tabelas_relacionamentos.sql](alter_tabelas_relacionamentos.sql), [insert_dados.sql](insert_dados.sql).

---

## 🎯 Objetivo da Aula
1. Consolidar o uso de **DDL** (`CREATE TABLE` e `ALTER TABLE`) a partir de um esquema previamente normalizado até a 3ª Forma Normal.
2. Compreender a **ordem de dependência** para criação de tabelas e inserção de dados (`INSERT INTO`).
3. Aplicar restrições de integridade física: Chaves Primárias (`PRIMARY KEY`), Estrangeiras (`FOREIGN KEY`), Unicidade (`UNIQUE`) e Não-Nulos (`NOT NULL`).

---

## 1. DDL: Criação das Tabelas (`CREATE TABLE`)

Na normalização do arquivo [dados_hospital.csv](dados_hospital.csv), identificamos que atributos multivalorados (telefones, alergias) e dependências parciais/transitivas (dados do médico, convênio, especialidade) precisavam de tabelas próprias.

### 1.1. Tabelas Independentes (Entidades Fortes)
Devem ser criadas primeiro, pois não dependem de nenhuma outra tabela:
* `Especialidade`, `Convenio`, `Procedimento`, `Sala`, `Medicamento`, `Paciente`, `Medico`.

```sql
CREATE TABLE Medico (
    ID_Medico SERIAL PRIMARY KEY,
    CRM VARCHAR(20) NOT NULL,
    UF_CRM CHAR(2) NOT NULL,
    Nome_Medico VARCHAR(255) NOT NULL,
    UNIQUE (CRM, UF_CRM) -- Evita médicos duplicados no mesmo estado
);
```

### 1.2. Tabelas Dependentes e Associativas
Criadas em seguida, pois recebem referências das tabelas fortes:
* `Paciente_Telefone`, `Paciente_Alergia`, `Paciente_Convenio`, `Medico_Especialidade`, `Consulta`, `Consulta_Procedimento`, `Prescricao`.

---

## 2. DDL: Modificações e Integridade (`ALTER TABLE`)

O comando `ALTER TABLE` permite ajustar a estrutura do banco após a criação das tabelas, sem precisar recriá-las do zero.

### 2.1. Adicionando Chaves Estrangeiras (`FOREIGN KEY`)
Garante que uma consulta só possa ser agendada para um paciente e médico que realmente existem no banco:

```sql
ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_paciente 
    FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente),
    ADD CONSTRAINT fk_consulta_medico 
    FOREIGN KEY (ID_Medico) REFERENCES Medico(ID_Medico),
    ADD CONSTRAINT fk_consulta_sala 
    FOREIGN KEY (ID_Sala) REFERENCES Sala(ID_Sala);
```

---

## 3. DML: Carga de Dados (`INSERT INTO`)

A regra de ouro da inserção de dados em bancos relacionais:
> **Inserções devem seguir estritamente o fluxo da hierarquia de dependência.** Não é possível inserir uma `Consulta` antes de inserir o `Paciente`, o `Medico` e a `Sala`.

### 3.1. Ordem Prática de Execução:
1. **Passo 1:** Inserir Domínios (`Especialidade`, `Convenio`, `Procedimento`, `Sala`, `Medicamento`).
2. **Passo 2:** Inserir Pessoas (`Paciente`, `Medico`).
3. **Passo 3:** Inserir Atributos Dependentes (`Paciente_Telefone`, `Paciente_Alergia`, `Medico_Especialidade`).
4. **Passo 4:** Inserir o Evento Central (`Consulta`).
5. **Passo 5:** Inserir Detalhes do Atendimento (`Consulta_Procedimento`, `Prescricao`).

```sql
-- Exemplo de inserção do paciente derivado da primeira linha do CSV:
INSERT INTO Paciente (CPF, Nome_Completo, Data_Nascimento)
VALUES ('11111111111', 'João Silva', '1985-04-12');

-- Inserindo os telefones atômicos do João Silva (ID 1)
INSERT INTO Paciente_Telefone (ID_Paciente, Numero) VALUES 
(1, '(11) 9999-1111'),
(1, '(11) 3333-2222');
```

---

## 📝 Exercícios de Fixação da Aula 04
1. Verifique se todas as tabelas foram criadas com o comando `\dt` (no psql) ou inspecione o esquema via DBeaver/pgAdmin.
2. Tente inserir uma `Consulta` passando um `ID_Paciente = 9999` (inexistente) e observe a trava de integridade referencial do SGBD.
3. Tente cadastrar um médico com o mesmo CRM e UF de um médico já existente para validar a constraint `UNIQUE`.
