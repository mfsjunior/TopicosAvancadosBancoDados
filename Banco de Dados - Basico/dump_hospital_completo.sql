-- =============================================================================
-- BANCO DE DADOS HOSPITALAR: SCRIPT COMPLETO E UNIFICADO (DDL + DML)
-- Compatível com: PostgreSQL (DBeaver, pgAdmin, VS Code, psql)
-- =============================================================================

-- =============================================================================
-- 1. LIMPEZA PRÉVIA DE TABELAS (Permite reexecutar sem conflito)
-- =============================================================================
DROP TABLE IF EXISTS Prescricao CASCADE;
DROP TABLE IF EXISTS Consulta_Procedimento CASCADE;
DROP TABLE IF EXISTS Consulta CASCADE;
DROP TABLE IF EXISTS Equipamento CASCADE;
DROP TABLE IF EXISTS Medico_Especialidade CASCADE;
DROP TABLE IF EXISTS Paciente_Convenio CASCADE;
DROP TABLE IF EXISTS Paciente_Alergia CASCADE;
DROP TABLE IF EXISTS Paciente_Telefone CASCADE;
DROP TABLE IF EXISTS Paciente CASCADE;
DROP TABLE IF EXISTS Medico CASCADE;
DROP TABLE IF EXISTS Medicamento CASCADE;
DROP TABLE IF EXISTS Sala CASCADE;
DROP TABLE IF EXISTS Procedimento CASCADE;
DROP TABLE IF EXISTS Convenio CASCADE;
DROP TABLE IF EXISTS Especialidade CASCADE;

-- =============================================================================
-- 2. CRIAÇÃO DAS TABELAS (DDL)
-- =============================================================================

-- Domínios e Entidades Independentes
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

-- Entidades Pessoais (Paciente e Médico)
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

-- Relacionamentos e Entidades de Vínculo
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

-- O Evento Central: Consulta
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

-- Pós-Consulta (Receitas e Procedimentos Realizados)
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

-- =============================================================================
-- 3. CHAVES ESTRANGEIRAS E INTEGRIDADE REFERENCIAL (ALTER TABLE)
-- =============================================================================

ALTER TABLE Paciente_Telefone
    ADD CONSTRAINT fk_paciente_telefone_paciente
    FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE;

ALTER TABLE Paciente_Alergia
    ADD CONSTRAINT fk_paciente_alergia_paciente
    FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE;

ALTER TABLE Paciente_Convenio
    ADD CONSTRAINT fk_paciente_convenio_paciente
    FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente)
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_paciente_convenio_convenio
    FOREIGN KEY (ID_Convenio) REFERENCES Convenio(ID_Convenio)
    ON DELETE CASCADE;

ALTER TABLE Medico_Especialidade
    ADD CONSTRAINT fk_medico_especialidade_medico
    FOREIGN KEY (ID_Medico) REFERENCES Medico(ID_Medico)
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_medico_especialidade_especialidade
    FOREIGN KEY (ID_Especialidade) REFERENCES Especialidade(ID_Especialidade)
    ON DELETE CASCADE;

ALTER TABLE Equipamento
    ADD CONSTRAINT fk_equipamento_sala
    FOREIGN KEY (ID_Sala) REFERENCES Sala(ID_Sala)
    ON DELETE SET NULL;

ALTER TABLE Consulta
    ADD CONSTRAINT fk_consulta_paciente
    FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente),
    ADD CONSTRAINT fk_consulta_medico
    FOREIGN KEY (ID_Medico) REFERENCES Medico(ID_Medico),
    ADD CONSTRAINT fk_consulta_especialidade
    FOREIGN KEY (ID_Especialidade) REFERENCES Especialidade(ID_Especialidade),
    ADD CONSTRAINT fk_consulta_sala
    FOREIGN KEY (ID_Sala) REFERENCES Sala(ID_Sala),
    ADD CONSTRAINT fk_consulta_paciente_convenio
    FOREIGN KEY (ID_Paciente_Convenio) REFERENCES Paciente_Convenio(ID_Paciente_Convenio);

ALTER TABLE Consulta_Procedimento
    ADD CONSTRAINT fk_consulta_procedimento_consulta
    FOREIGN KEY (ID_Consulta) REFERENCES Consulta(ID_Consulta)
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_consulta_procedimento_procedimento
    FOREIGN KEY (ID_Procedimento) REFERENCES Procedimento(ID_Procedimento);

ALTER TABLE Prescricao
    ADD CONSTRAINT fk_prescricao_consulta
    FOREIGN KEY (ID_Consulta) REFERENCES Consulta(ID_Consulta)
    ON DELETE CASCADE,
    ADD CONSTRAINT fk_prescricao_medicamento
    FOREIGN KEY (ID_Medicamento) REFERENCES Medicamento(ID_Medicamento);

-- =============================================================================
-- 4. CARGA DE DADOS (INSERT INTO)
-- =============================================================================

-- Domínios e Entidades Independentes
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

-- Entidades Pessoais
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

-- Relacionamentos e Vínculos
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

-- Evento Central: Consultas
INSERT INTO Consulta (ID_Consulta, ID_Paciente, ID_Medico, ID_Especialidade, ID_Sala, ID_Paciente_Convenio, Data_Hora_Inicio, Duracao_Minutos, Status) VALUES
(1, 1, 1, 1, 1, 1, '2026-09-25 09:00:00', 30, 'Agendada'),
(2, 2, 2, 2, 2, 2, '2026-09-25 10:30:00', 45, 'Realizada'),
(3, 3, 3, 3, 3, NULL, '2026-09-26 14:00:00', 20, 'Agendada');

-- Detalhes da Consulta
INSERT INTO Consulta_Procedimento (ID_Consulta, ID_Procedimento) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3);

INSERT INTO Prescricao (ID_Consulta, ID_Medicamento, Dosagem, Instrucoes_Uso) VALUES
(1, 4, '1 comprimido', 'Tomar pela manhã todos os dias'),
(2, 2, '40 gotas', 'Tomar de 8 em 8 horas em caso de dor');

-- =============================================================================
-- 5. AJUSTE DAS SEQUÊNCIAS (Para os próximos INSERTs automáticos funcionarem)
-- =============================================================================
SELECT setval('especialidade_id_especialidade_seq', (SELECT MAX(ID_Especialidade) FROM Especialidade));
SELECT setval('convenio_id_convenio_seq', (SELECT MAX(ID_Convenio) FROM Convenio));
SELECT setval('procedimento_id_procedimento_seq', (SELECT MAX(ID_Procedimento) FROM Procedimento));
SELECT setval('sala_id_sala_seq', (SELECT MAX(ID_Sala) FROM Sala));
SELECT setval('medicamento_id_medicamento_seq', (SELECT MAX(ID_Medicamento) FROM Medicamento));
SELECT setval('paciente_id_paciente_seq', (SELECT MAX(ID_Paciente) FROM Paciente));
SELECT setval('paciente_telefone_id_telefone_seq', (SELECT MAX(ID_Telefone) FROM Paciente_Telefone));
SELECT setval('paciente_alergia_id_alergia_seq', (SELECT MAX(ID_Alergia) FROM Paciente_Alergia));
SELECT setval('medico_id_medico_seq', (SELECT MAX(ID_Medico) FROM Medico));
SELECT setval('paciente_convenio_id_paciente_convenio_seq', (SELECT MAX(ID_Paciente_Convenio) FROM Paciente_Convenio));
SELECT setval('equipamento_id_equipamento_seq', (SELECT MAX(ID_Equipamento) FROM Equipamento));
SELECT setval('consulta_id_consulta_seq', (SELECT MAX(ID_Consulta) FROM Consulta));
SELECT setval('consulta_procedimento_id_consulta_procedimento_seq', (SELECT MAX(ID_Consulta_Procedimento) FROM Consulta_Procedimento));
SELECT setval('prescricao_id_prescricao_seq', (SELECT MAX(ID_Prescricao) FROM Prescricao));
