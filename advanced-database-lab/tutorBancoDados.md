# Laboratório de Banco de Dados

Neste laboratório, simularemos e evoluiremos uma **Hospital** que sofre com problemas de concorrência, performance e modelagem à medida que cresce.

---

## 🚀 Como Iniciar

1. **Clone o repositório** e abra o terminal na pasta raiz do projeto.
2. **Copie o arquivo de configuração (.env):**
   - *Windows (PowerShell)*: `Copy-Item .env.example .env`
   - *Linux/Mac*: `cp .env.example .env`
3. **Suba o ambiente (PostgreSQL):**
   - *Windows (PowerShell)*: `.\scripts\start.ps1`
   - *Linux/Mac (Bash)*: `./scripts\start.sh`

---

## 🔌 Conectando aos Bancos de Dados

Para realizar as consultas e laboratórios, recomendamos fortemente o uso do **DBeaver** ou do **VSCode**.

### Opção A: DBeaver (Recomendado)

#### PostgreSQL
- Abra o DBeaver, clique em **Nova Conexão** e selecione **PostgreSQL**.
- **Host**: `localhost` | **Port**: `5432` | **Database**: `postgres`
- **Username**: `adv_user` | **Password**: `adv_password`
- Teste a conexão e salve.

### Opção B: Visual Studio Code

#### PostgreSQL (via extensão SQLTools)
- Instale a extensão **SQLTools** + **SQLTools PostgreSQL/Redshift Driver**.
- Adicione uma conexão PostgreSQL com:
  - **Server Address**: `localhost` | **Port**: `5432` | **Database**: `postgres`
  - **Username**: `adv_user` | **Password**: `adv_password`

---

## 🛠️ Executando as Tarefas

Quando conseguir conectar estando com o Docker rodando e o banco conectado na IDE, execute os comandos SQL abaixo exatamente na ordem fornecida.

> **Importante:** Tente ao máximo seguir a ordem, pois se executar de outra forma dará erro de relacionamento de chaves estrangeiras.

---

### 1. Criando o Banco de Dados

Rode este comando (estando conectado inicialmente ao banco genérico `postgres`):

```sql
CREATE DATABASE sghc;
```

**⚠️ AVISO:** Após criar o banco, troque a sua conexão na IDE (DBeaver/VSCode) para o **novo banco de dados criado (`sghc`)** antes de continuar para os próximos passos.

---

### 2. Resetando as Tabelas (Truncate)
*(Faça isso apenas se já possuir as tabelas criadas e quiser limpar os dados para reiniciar o laboratório)*

```sql
TRUNCATE TABLE
    Prescricao,
    Consulta_Procedimento,
    Consulta,
    Equipamento,
    Medico_Especialidade,
    Paciente_Convenio,
    Medico,
    Paciente_Alergia,
    Paciente_Telefone,
    Paciente,
    Medicamento,
    Sala,
    Procedimento,
    Convenio,
    Especialidade
RESTART IDENTITY CASCADE;
```

---

### 3. Criação de Tabelas e Relacionamentos

Rode os comandos abaixo no banco `sghc` para construir a estrutura.

```sql
-- 1. Domínios e Entidades Independentes
CREATE TABLE Especialidade (
    ID_Especialidade SERIAL PRIMARY KEY,
    Nome_Especialidade VARCHAR(100) NOT NULL,
    Conselho VARCHAR(50)
);

CREATE TABLE Convenio (
    ID_Convenio SERIAL PRIMARY KEY,
    CNPJ VARCHAR(14) UNIQUE NOT NULL,
    Nome_Operadora VARCHAR(255) NOT NULL,
    Tipo_Plano VARCHAR(100)
);

CREATE TABLE Procedimento (
    ID_Procedimento SERIAL PRIMARY KEY,
    Codigo_TUSS VARCHAR(8) UNIQUE NOT NULL,
    Nome_Procedimento VARCHAR(255) NOT NULL,
    Valor_Base NUMERIC(10, 2)
);

CREATE TABLE Sala (
    ID_Sala SERIAL PRIMARY KEY,
    Numero_Sala INTEGER UNIQUE NOT NULL
);

CREATE TABLE Medicamento (
    ID_Medicamento SERIAL PRIMARY KEY,
    Nome_Medicamento VARCHAR(255) NOT NULL
);

-- 2. Entidades Pessoais (Paciente e Médico)
CREATE TABLE Paciente (
    ID_Paciente SERIAL PRIMARY KEY,
    CPF VARCHAR(11) UNIQUE NOT NULL,
    Nome_Completo VARCHAR(255) NOT NULL,
    Data_Nascimento DATE
);

CREATE TABLE Paciente_Telefone (
    ID_Telefone SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL,
    Numero VARCHAR(20) NOT NULL
);

CREATE TABLE Paciente_Alergia (
    ID_Alergia SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL,
    Descricao VARCHAR(255) NOT NULL
);

CREATE TABLE Medico (
    ID_Medico SERIAL PRIMARY KEY,
    CRM VARCHAR(20) NOT NULL,
    UF_CRM CHAR(2) NOT NULL,
    Nome_Medico VARCHAR(255) NOT NULL,
    UNIQUE (CRM, UF_CRM)
);

-- 3. Relacionamentos e Entidades de Vínculo
CREATE TABLE Paciente_Convenio (
    ID_Paciente_Convenio SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL,
    ID_Convenio INTEGER NOT NULL,
    Numero_Carteirinha VARCHAR(50),
    Data_Validade DATE
);

CREATE TABLE Medico_Especialidade (
    ID_Medico INTEGER NOT NULL,
    ID_Especialidade INTEGER NOT NULL,
    PRIMARY KEY (ID_Medico, ID_Especialidade)
);

CREATE TABLE Equipamento (
    ID_Equipamento SERIAL PRIMARY KEY,
    ID_Sala INTEGER,
    Numero_Serie VARCHAR(100) UNIQUE NOT NULL,
    Nome_Equipamento VARCHAR(100) NOT NULL,
    Data_Manutencao DATE
);

-- 4. O Evento Central: A Consulta
CREATE TABLE Consulta (
    ID_Consulta SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL,
    ID_Medico INTEGER NOT NULL,
    ID_Especialidade INTEGER NOT NULL,
    ID_Sala INTEGER NOT NULL,
    ID_Paciente_Convenio INTEGER,
    Data_Hora_Inicio TIMESTAMP NOT NULL,
    Duracao_Minutos INTEGER,
    Status VARCHAR(50)
);

-- 5. Pós-Consulta (Receitas e Atos Médicos)
CREATE TABLE Consulta_Procedimento (
    ID_Consulta_Procedimento SERIAL PRIMARY KEY,
    ID_Consulta INTEGER NOT NULL,
    ID_Procedimento INTEGER NOT NULL
);

CREATE TABLE Prescricao (
    ID_Prescricao SERIAL PRIMARY KEY,
    ID_Consulta INTEGER NOT NULL,
    ID_Medicamento INTEGER NOT NULL,
    Dosagem VARCHAR(255),
    Instrucoes_Uso TEXT
);

-- CHAVES ESTRANGEIRAS (FOREIGN KEYS)

-- 1. Paciente_Telefone
ALTER TABLE Paciente_Telefone
    ADD CONSTRAINT fk_paciente_telefone_paciente
    FOREIGN KEY (ID_Paciente)
    REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE;

-- 2. Paciente_Alergia
ALTER TABLE Paciente_Alergia
    ADD CONSTRAINT fk_paciente_alergia_paciente
    FOREIGN KEY (ID_Paciente)
    REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE;

-- 3. Paciente_Convenio
ALTER TABLE Paciente_Convenio
    ADD CONSTRAINT fk_paciente_convenio_paciente
    FOREIGN KEY (ID_Paciente)
    REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE;

ALTER TABLE Paciente_Convenio
    ADD CONSTRAINT fk_paciente_convenio_convenio
    FOREIGN KEY (ID_Convenio)
    REFERENCES Convenio(ID_Convenio)
    ON DELETE CASCADE;

-- 4. Medico_Especialidade
ALTER TABLE Medico_Especialidade
    ADD CONSTRAINT fk_medico_especialidade_medico
    FOREIGN KEY (ID_Medico)
    REFERENCES Medico(ID_Medico)
    ON DELETE CASCADE;

ALTER TABLE Medico_Especialidade
    ADD CONSTRAINT fk_medico_especialidade_especialidade
    FOREIGN KEY (ID_Especialidade)
    REFERENCES Especialidade(ID_Especialidade)
    ON DELETE CASCADE;

-- 5. Equipamento
ALTER TABLE Equipamento
    ADD CONSTRAINT fk_equipamento_sala
    FOREIGN KEY (ID_Sala)
    REFERENCES Sala(ID_Sala)
    ON DELETE SET NULL;

-- 6. Consulta
ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_paciente
    FOREIGN KEY (ID_Paciente)
    REFERENCES Paciente(ID_Paciente);

ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_medico
    FOREIGN KEY (ID_Medico)
    REFERENCES Medico(ID_Medico);

ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_especialidade
    FOREIGN KEY (ID_Especialidade)
    REFERENCES Especialidade(ID_Especialidade);

ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_sala
    FOREIGN KEY (ID_Sala)
    REFERENCES Sala(ID_Sala);

ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_paciente_convenio
    FOREIGN KEY (ID_Paciente_Convenio)
    REFERENCES Paciente_Convenio(ID_Paciente_Convenio);

-- 7. Consulta_Procedimento
ALTER TABLE Consulta_Procedimento
    ADD CONSTRAINT fk_consulta_procedimento_consulta
    FOREIGN KEY (ID_Consulta)
    REFERENCES Consulta(ID_Consulta)
    ON DELETE CASCADE;

ALTER TABLE Consulta_Procedimento
    ADD CONSTRAINT fk_consulta_procedimento_procedimento
    FOREIGN KEY (ID_Procedimento)
    REFERENCES Procedimento(ID_Procedimento);

-- 8. Prescricao
ALTER TABLE Prescricao
    ADD CONSTRAINT fk_prescricao_consulta
    FOREIGN KEY (ID_Consulta)
    REFERENCES Consulta(ID_Consulta)
    ON DELETE CASCADE;

ALTER TABLE Prescricao
    ADD CONSTRAINT fk_prescricao_medicamento
    FOREIGN KEY (ID_Medicamento)
    REFERENCES Medicamento(ID_Medicamento);
```

---

### 4. Inserção de Dados (Inserts de Teste)

```sql
-- 1. Domínios e Entidades Independentes
INSERT INTO Especialidade (ID_Especialidade, Nome_Especialidade, Conselho) VALUES
(1, 'Cardiologia', 'CRM'),
(2, 'Ortopedia', 'CRM'),
(3, 'Pediatria', 'CRM'),
(4, 'Dermatologia', 'CRM');

INSERT INTO Convenio (ID_Convenio, CNPJ, Nome_Operadora, Tipo_Plano) VALUES
(1, '12345678000199', 'Unimed', 'Nacional Enfermaria'),
(2, '98765432000188', 'Bradesco Saúde', 'Top Nacional Quarto'),
(3, '45612378000155', 'SulAmérica', 'Exato Nacional');

INSERT INTO Procedimento (ID_Procedimento, Codigo_TUSS, Nome_Procedimento, Valor_Base) VALUES
(1, '10101012', 'Consulta em consultório', 150.00),
(2, '20102018', 'Eletrocardiograma', 80.50),
(3, '30101018', 'Raio-X de Tórax', 120.00),
(4, '40101010', 'Exame de Sangue Básico', 50.00);

INSERT INTO Sala (ID_Sala, Numero_Sala) VALUES
(1, 101), (2, 102), (3, 103), (4, 201), (5, 202);

INSERT INTO Medicamento (ID_Medicamento, Nome_Medicamento) VALUES
(1, 'Dipirona 500mg'),
(2, 'Ibuprofeno 400mg'),
(3, 'Amoxicilina 500mg'),
(4, 'Losartana 50mg');

-- 2. Entidades Pessoais (Paciente e Médico)
INSERT INTO Paciente (ID_Paciente, CPF, Nome_Completo, Data_Nascimento) VALUES
(1, '11122233344', 'João da Silva', '1985-05-15'),
(2, '55566677788', 'Maria Oliveira', '1992-10-20'),
(3, '99988877766', 'Carlos Souza', '1978-03-10');

INSERT INTO Paciente_Telefone (ID_Paciente, Numero) VALUES
(1, '(11) 98765-4321'),
(1, '(11) 3214-5678'),
(2, '(21) 99999-8888'),
(3, '(31) 97777-6666');

INSERT INTO Paciente_Alergia (ID_Paciente, Descricao) VALUES
(1, 'Alergia a Penicilina'),
(2, 'Intolerância à Lactose');

INSERT INTO Medico (ID_Medico, CRM, UF_CRM, Nome_Medico) VALUES
(1, '12345', 'SP', 'Dr. Roberto Costa'),
(2, '54321', 'RJ', 'Dra. Ana Paula'),
(3, '98765', 'MG', 'Dr. Marcos Lima');

-- 3. Relacionamentos e Entidades de Vínculo
INSERT INTO Paciente_Convenio (ID_Paciente, ID_Convenio, Numero_Carteirinha, Data_Validade) VALUES
(1, 1, 'UNI123456789', '2027-12-31'),
(2, 2, 'BRA987654321', '2026-06-30');

INSERT INTO Medico_Especialidade (ID_Medico, ID_Especialidade) VALUES
(1, 1),
(2, 2),
(3, 3),
(1, 4);

INSERT INTO Equipamento (ID_Equipamento, ID_Sala, Numero_Serie, Nome_Equipamento, Data_Manutencao) VALUES
(1, 1, 'EQP-001', 'Máquina de ECG', '2026-08-15'),
(2, 2, 'EQP-002', 'Aparelho de Raio-X', '2026-07-10'),
(3, 3, 'EQP-003', 'Balança Pediátrica', '2026-09-01');

-- 4. O Evento Central: A Consulta
INSERT INTO Consulta (ID_Consulta, ID_Paciente, ID_Medico, ID_Especialidade, ID_Sala, ID_Paciente_Convenio, Data_Hora_Inicio, Duracao_Minutos, Status) VALUES
(1, 1, 1, 1, 1, 1, '2026-09-25 09:00:00', 30, 'Agendada'),
(2, 2, 2, 2, 2, 2, '2026-09-25 10:30:00', 45, 'Realizada'),
(3, 3, 3, 3, 3, NULL, '2026-09-26 14:00:00', 20, 'Agendada');

-- 5. Pós-Consulta (Receitas e Atos Médicos)
INSERT INTO Consulta_Procedimento (ID_Consulta, ID_Procedimento) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3);

INSERT INTO Prescricao (ID_Consulta, ID_Medicamento, Dosagem, Instrucoes_Uso) VALUES
(1, 4, '1 comprimido', 'Tomar pela manhã todos os dias'),
(2, 2, '40 gotas', 'Tomar de 8 em 8 horas em caso de dor');
```
