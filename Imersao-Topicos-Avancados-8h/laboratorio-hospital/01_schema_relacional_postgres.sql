-- ============================================================================
-- SCRIPT RELACIONAL AVANÇADO (POSTGRESQL 15+)
-- Laboratório End-to-End: Normalização, DDL, Índices, Explain e Concorrência
-- Origem dos Dados: dados_hospital.csv
-- ============================================================================

-- 1. LIMPEZA PREVENTIVA
DROP SCHEMA IF EXISTS hospital_lab CASCADE;
CREATE SCHEMA hospital_lab;
SET search_path TO hospital_lab, public;

-- ============================================================================
-- 2. DDL NORMALIZADO (3ª FORMA NORMAL)
-- ============================================================================

-- Entidades Independentes (Domínios)
CREATE TABLE Especialidade (
    ID_Especialidade SERIAL PRIMARY KEY,
    Nome_Especialidade VARCHAR(100) NOT NULL UNIQUE,
    Conselho VARCHAR(100)
);

CREATE TABLE Convenio (
    ID_Convenio SERIAL PRIMARY KEY,
    CNPJ VARCHAR(20) UNIQUE,
    Nome_Operadora VARCHAR(100) NOT NULL UNIQUE,
    Telefone_Central VARCHAR(30)
);

CREATE TABLE Procedimento (
    ID_Procedimento SERIAL PRIMARY KEY,
    Codigo_TUSS VARCHAR(10) NOT NULL UNIQUE,
    Nome_Procedimento VARCHAR(255) NOT NULL,
    Valor_Base NUMERIC(10, 2) NOT NULL CHECK (Valor_Base >= 0)
);

CREATE TABLE Medicamento (
    ID_Medicamento SERIAL PRIMARY KEY,
    Nome_Medicamento VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Sala (
    ID_Sala SERIAL PRIMARY KEY,
    Numero_Sala INTEGER NOT NULL UNIQUE,
    Andar VARCHAR(50) NOT NULL
);

CREATE TABLE Equipamento (
    ID_Equipamento SERIAL PRIMARY KEY,
    ID_Sala INTEGER NOT NULL REFERENCES Sala(ID_Sala) ON DELETE CASCADE,
    Nome_Equipamento VARCHAR(150) NOT NULL
);

-- Entidades Pessoais
CREATE TABLE Paciente (
    ID_Paciente SERIAL PRIMARY KEY,
    CPF VARCHAR(14) NOT NULL UNIQUE,
    Nome_Completo VARCHAR(255) NOT NULL,
    Logradouro VARCHAR(255),
    Cidade VARCHAR(100),
    UF CHAR(2),
    CEP VARCHAR(10)
);

CREATE TABLE Paciente_Telefone (
    ID_Telefone SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE,
    Numero_Telefone VARCHAR(30) NOT NULL
);

CREATE TABLE Paciente_Alergia (
    ID_Alergia SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE,
    Nome_Alergia VARCHAR(100) NOT NULL
);

CREATE TABLE Medico (
    ID_Medico SERIAL PRIMARY KEY,
    CRM VARCHAR(20) NOT NULL,
    UF_CRM CHAR(2) NOT NULL,
    Nome_Medico VARCHAR(255) NOT NULL,
    CONSTRAINT uq_medico_crm UNIQUE (CRM, UF_CRM)
);

-- Associativa: Especialidades que o médico atende
CREATE TABLE Medico_Especialidade (
    ID_Medico INTEGER NOT NULL REFERENCES Medico(ID_Medico) ON DELETE CASCADE,
    ID_Especialidade INTEGER NOT NULL REFERENCES Especialidade(ID_Especialidade) ON DELETE RESTRICT,
    PRIMARY KEY (ID_Medico, ID_Especialidade)
);

-- Associativa: Planos dos pacientes
CREATE TABLE Paciente_Convenio (
    ID_Paciente_Convenio SERIAL PRIMARY KEY,
    ID_Paciente INTEGER NOT NULL REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE,
    ID_Convenio INTEGER NOT NULL REFERENCES Convenio(ID_Convenio) ON DELETE RESTRICT,
    Numero_Carteirinha VARCHAR(50) NOT NULL,
    CONSTRAINT uq_paciente_convenio UNIQUE (ID_Paciente, ID_Convenio)
);

-- Transacional Central: Consulta / Atendimento
CREATE TABLE Consulta (
    ID_Consulta SERIAL PRIMARY KEY,
    ID_Atendimento_Origem INTEGER UNIQUE, -- Mapeia o ID_Atendimento do CSV original
    Data_Hora_Inicio TIMESTAMP NOT NULL,
    ID_Paciente INTEGER NOT NULL REFERENCES Paciente(ID_Paciente) ON DELETE RESTRICT,
    ID_Medico INTEGER NOT NULL REFERENCES Medico(ID_Medico) ON DELETE RESTRICT,
    ID_Especialidade INTEGER NOT NULL REFERENCES Especialidade(ID_Especialidade) ON DELETE RESTRICT,
    ID_Sala INTEGER NOT NULL REFERENCES Sala(ID_Sala) ON DELETE RESTRICT,
    ID_Paciente_Convenio INTEGER REFERENCES Paciente_Convenio(ID_Paciente_Convenio) ON DELETE SET NULL,
    Valor_Total_Faturado NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (Valor_Total_Faturado >= 0),
    Status VARCHAR(50) NOT NULL CHECK (Status IN ('Realizada', 'Cancelada', 'Paciente Faltou', 'Agendada'))
);

-- Detalhamento N:M: Procedimentos da Consulta
CREATE TABLE Consulta_Procedimento (
    ID_Consulta_Procedimento SERIAL PRIMARY KEY,
    ID_Consulta INTEGER NOT NULL REFERENCES Consulta(ID_Consulta) ON DELETE CASCADE,
    ID_Procedimento INTEGER NOT NULL REFERENCES Procedimento(ID_Procedimento) ON DELETE RESTRICT,
    Valor_Cobrado NUMERIC(10, 2) NOT NULL CHECK (Valor_Cobrado >= 0)
);

-- Detalhamento N:M: Prescrições da Consulta
CREATE TABLE Prescricao (
    ID_Prescricao SERIAL PRIMARY KEY,
    ID_Consulta INTEGER NOT NULL REFERENCES Consulta(ID_Consulta) ON DELETE CASCADE,
    ID_Medicamento INTEGER NOT NULL REFERENCES Medicamento(ID_Medicamento) ON DELETE RESTRICT,
    Posologia_Instrucoes TEXT NOT NULL
);

-- ============================================================================
-- 3. CARGA DE DADOS (Extraídos e Normalizados do dados_hospital.csv)
-- ============================================================================

-- Especialidades
INSERT INTO Especialidade (ID_Especialidade, Nome_Especialidade, Conselho) VALUES
(1, 'Cardiologia', 'Soc. Bras. Cardiologia'),
(2, 'Clínico Geral', 'Conselho de Clínica'),
(3, 'Ortopedia', 'Soc. Bras. Ortopedia'),
(4, 'Pediatria', 'Soc. Bras. Pediatria'),
(5, 'Traumatologia', 'Soc. Bras. Traumatologia'),
(6, 'Geriatria', 'Soc. Bras. Geriatria');

-- Convênios
INSERT INTO Convenio (ID_Convenio, Nome_Operadora, CNPJ, Telefone_Central) VALUES
(1, 'Unimed', '12.345.678/0001-90', '0800-111-2222'),
(2, 'Bradesco Saúde', '98.765.432/0001-10', '0800-333-4444'),
(3, 'SulAmérica', '45.678.901/0001-50', '0800-555-6666'),
(4, 'Amil', '11.222.333/0001-44', '0800-999-8888'),
(5, 'Particular', NULL, NULL);

-- Procedimentos
INSERT INTO Procedimento (ID_Procedimento, Codigo_TUSS, Nome_Procedimento, Valor_Base) VALUES
(1, '1010', 'Eletrocardiograma', 150.00),
(2, '2020', 'Aferição de Pressão', 0.00),
(3, '3030', 'Exame Clínico', 150.00),
(4, '4040', 'Raio-X de Joelho', 300.00),
(5, '5050', 'Curativo', 50.00),
(6, '6060', 'Teste do Pezinho', 100.00),
(7, '7070', 'Retirada de Gesso', 80.00),
(8, '8080', 'Teste Glicemia', 20.00),
(9, '9090', 'Teste Ergométrico', 300.00);

-- Medicamentos
INSERT INTO Medicamento (ID_Medicamento, Nome_Medicamento) VALUES
(1, 'Aspirina 100mg'),
(2, 'Losartana 50mg'),
(3, 'Ibuprofeno 400mg'),
(4, 'Dipirona Gotas'),
(5, 'Vitamina D'),
(6, 'Metformina 500mg'),
(7, 'Paracetamol 750mg'),
(8, 'Atenolol 25mg');

-- Salas
INSERT INTO Sala (ID_Sala, Numero_Sala, Andar) VALUES
(1, 101, '1º Andar'),
(2, 102, '1º Andar'),
(3, 205, '2º Andar'),
(4, 301, '3º Andar');

-- Equipamentos
INSERT INTO Equipamento (ID_Sala, Nome_Equipamento) VALUES
(1, 'Máquina de ECG'),
(1, 'Desfibrilador'),
(2, 'Estetoscópio'),
(2, 'Balança'),
(3, 'Aparelho de Raio-X'),
(4, 'Maca Infantil'),
(4, 'Balança Pediátrica');

-- Pacientes
INSERT INTO Paciente (ID_Paciente, CPF, Nome_Completo, Logradouro, Cidade, UF, CEP) VALUES
(1, '111.111.111-11', 'João Silva', 'Rua das Flores 123', 'São Paulo', 'SP', '01000-000'),
(2, '222.222.222-22', 'Maria Souza', 'Av. Paulista 900', 'São Paulo', 'SP', '01310-100'),
(3, '333.333.333-33', 'Pedro Gomes', 'Rua XV de Novembro 45', 'Curitiba', 'PR', '80020-310'),
(4, '444.444.444-44', 'Ana Oliveira', 'Praça Sete 10', 'Belo Horizonte', 'MG', '30130-010'),
(5, '555.555.555-55', 'Lucas Martins', 'Rua Augusta 1500', 'São Paulo', 'SP', '01305-100'),
(6, '666.666.666-66', 'Carla Dias', 'Av. Brasil 100', 'Rio de Janeiro', 'RJ', '20040-000');

-- Telefones (1FN resolvida)
INSERT INTO Paciente_Telefone (ID_Paciente, Numero_Telefone) VALUES
(1, '(11) 9999-1111'),
(1, '(11) 3333-2222'),
(2, '(22) 8888-4444'),
(3, '(33) 7777-5555'),
(4, '(44) 6666-1111'),
(4, '(44) 2222-3333'),
(5, '(11) 5555-9999'),
(6, '(21) 1234-5678'),
(6, '(21) 9876-5432');

-- Alergias (1FN resolvida)
INSERT INTO Paciente_Alergia (ID_Paciente, Nome_Alergia) VALUES
(1, 'Amendoim'),
(1, 'Penicilina'),
(3, 'Frutos do Mar'),
(4, 'Poeira'),
(5, 'Iodo'),
(5, 'Dipirona');

-- Médicos
INSERT INTO Medico (ID_Medico, CRM, UF_CRM, Nome_Medico) VALUES
(1, '12345', 'SP', 'Dr. Carlos Almeida'),
(2, '54321', 'RJ', 'Dra. Ana Costa'),
(3, '98765', 'MG', 'Dr. Marcos Paulo');

-- Especialidades dos Médicos (N:M resolvido)
INSERT INTO Medico_Especialidade (ID_Medico, ID_Especialidade) VALUES
(1, 1), -- Dr. Carlos: Cardio
(1, 2), -- Dr. Carlos: Clínico
(1, 6), -- Dr. Carlos: Geriatria
(2, 3), -- Dra. Ana: Ortopedia
(2, 5), -- Dra. Ana: Traumatologia
(3, 4); -- Dr. Marcos: Pediatria

-- Carteirinhas dos Pacientes
INSERT INTO Paciente_Convenio (ID_Paciente_Convenio, ID_Paciente, ID_Convenio, Numero_Carteirinha) VALUES
(1, 1, 1, 'UNI-98765'),
(2, 2, 2, 'BRAD-123'),
(3, 3, 1, 'UNI-11223'),
(4, 2, 3, 'SUL-9988'),
(5, 4, 2, 'BRAD-999'),
(6, 1, 3, 'SUL-1234'),
(7, 6, 4, 'AMIL-5566'),
(8, 4, 4, 'AMIL-1122'),
(9, 5, 2, 'BRAD-777');

-- Consultas (Atendimentos 1001 a 1012)
INSERT INTO Consulta (ID_Consulta, ID_Atendimento_Origem, Data_Hora_Inicio, ID_Paciente, ID_Medico, ID_Especialidade, ID_Sala, ID_Paciente_Convenio, Valor_Total_Faturado, Status) VALUES
(1, 1001, '2023-10-15 08:00:00', 1, 1, 1, 1, 1, 150.00, 'Realizada'),
(2, 1002, '2023-10-15 09:00:00', 2, 1, 2, 2, 2, 200.00, 'Realizada'),
(3, 1003, '2023-10-15 10:00:00', 1, 2, 3, 3, NULL, 350.00, 'Realizada'),
(4, 1004, '2023-10-16 14:00:00', 3, 3, 4, 1, 3, 150.00, 'Realizada'),
(5, 1005, '2023-10-16 15:00:00', 2, 2, 3, 3, 4, 0.00, 'Cancelada'),
(6, 1006, '2023-10-17 08:30:00', 4, 1, 1, 1, 5, 150.00, 'Realizada'),
(7, 1007, '2023-10-17 11:00:00', 5, 3, 4, 4, NULL, 350.00, 'Realizada'),
(8, 1008, '2023-10-18 09:30:00', 1, 2, 5, 3, 6, 80.00, 'Realizada'),
(9, 1009, '2023-10-18 14:15:00', 3, 1, 2, 2, 3, 170.00, 'Realizada'),
(10, 1010, '2023-10-19 10:00:00', 6, 2, 3, 3, 7, 100.00, 'Realizada'),
(11, 1011, '2023-10-19 16:00:00', 4, 3, 4, 4, 8, 0.00, 'Paciente Faltou'),
(12, 1012, '2023-10-20 08:00:00', 5, 1, 1, 1, 9, 450.00, 'Realizada');

-- Procedimentos Faturados na Consulta
INSERT INTO Consulta_Procedimento (ID_Consulta, ID_Procedimento, Valor_Cobrado) VALUES
(1, 1, 150.00), -- 1001: ECG
(1, 2, 0.00),   -- 1001: Aferição
(2, 3, 200.00), -- 1002: Exame Clínico
(3, 4, 300.00), -- 1003: Raio-X Joelho
(3, 5, 50.00),  -- 1003: Curativo
(4, 3, 150.00), -- 1004: Exame Clínico
(6, 1, 150.00), -- 1006: ECG
(7, 3, 250.00), -- 1007: Exame Clínico
(7, 6, 100.00), -- 1007: Teste Pezinho
(8, 7, 80.00),  -- 1008: Retirada de Gesso
(9, 3, 150.00), -- 1009: Exame Clínico
(9, 8, 20.00),  -- 1009: Teste Glicemia
(10, 3, 100.00),-- 1010: Consulta Simples
(12, 1, 150.00),-- 1012: ECG
(12, 9, 300.00);-- 1012: Teste Ergométrico

-- Prescrições Emitidas
INSERT INTO Prescricao (ID_Consulta, ID_Medicamento, Posologia_Instrucoes) VALUES
(1, 1, '100mg 2x ao dia'),
(1, 2, '50mg 1x ao dia'),
(3, 3, '400mg 3x ao dia se dor'),
(4, 4, '35 gotas de 6 em 6 horas'),
(7, 5, '2 gotas ao dia pela manhã'),
(8, 6, '500mg 2x ao dia com alimentos'),
(10, 7, '750mg se dor'),
(12, 8, '25mg 1x ao dia pela manhã');

-- Atualiza as sequences de autoincremento
SELECT setval('Especialidade_ID_Especialidade_seq', (SELECT MAX(ID_Especialidade) FROM Especialidade));
SELECT setval('Convenio_ID_Convenio_seq', (SELECT MAX(ID_Convenio) FROM Convenio));
SELECT setval('Procedimento_ID_Procedimento_seq', (SELECT MAX(ID_Procedimento) FROM Procedimento));
SELECT setval('Medicamento_ID_Medicamento_seq', (SELECT MAX(ID_Medicamento) FROM Medicamento));
SELECT setval('Sala_ID_Sala_seq', (SELECT MAX(ID_Sala) FROM Sala));
SELECT setval('Paciente_ID_Paciente_seq', (SELECT MAX(ID_Paciente) FROM Paciente));
SELECT setval('Medico_ID_Medico_seq', (SELECT MAX(ID_Medico) FROM Medico));
SELECT setval('Consulta_ID_Consulta_seq', (SELECT MAX(ID_Consulta) FROM Consulta));

-- ============================================================================
-- 4. OTIMIZAÇÃO, ÍNDICES AVANÇADOS E DIAGNÓSTICO COM EXPLAIN
-- ============================================================================

-- 4.1. Índice Parcial para Consultas Atípicas (Falta ou Cancelamento)
-- Economiza espaço e indexa apenas as exceções
CREATE INDEX idx_consulta_anomala ON Consulta(ID_Consulta, Status)
WHERE Status IN ('Cancelada', 'Paciente Faltou');

-- 4.2. Índice B-Tree Composto para Agenda do Médico
-- Otimiza buscas por médico ordenadas por data
CREATE INDEX idx_consulta_medico_data ON Consulta(ID_Medico, Data_Hora_Inicio);

-- 4.3. Testando o Plano de Execução com EXPLAIN ANALYZE
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    c.ID_Consulta,
    c.Data_Hora_Inicio,
    p.Nome_Completo AS Paciente,
    m.Nome_Medico AS Medico,
    e.Nome_Especialidade AS Especialidade,
    c.Valor_Total_Faturado
FROM Consulta c
JOIN Paciente p ON c.ID_Paciente = p.ID_Paciente
JOIN Medico m ON c.ID_Medico = m.ID_Medico
JOIN Especialidade e ON c.ID_Especialidade = e.ID_Especialidade
WHERE c.ID_Medico = 1 AND c.Data_Hora_Inicio >= '2023-10-15'
ORDER BY c.Data_Hora_Inicio;

-- ============================================================================
-- 5. RELATÓRIO ANALÍTICO AVANÇADO (WINDOW FUNCTION)
-- ============================================================================
-- Lista os atendimentos mostrando a média móvel de faturamento por especialidade
SELECT 
    c.ID_Consulta,
    e.Nome_Especialidade,
    c.Data_Hora_Inicio,
    c.Valor_Total_Faturado,
    ROUND(AVG(c.Valor_Total_Faturado) OVER (PARTITION BY c.ID_Especialidade), 2) AS Media_Especialidade,
    DENSE_RANK() OVER (PARTITION BY c.ID_Especialidade ORDER BY c.Valor_Total_Faturado DESC) AS Rank_Faturamento
FROM Consulta c
JOIN Especialidade e ON c.ID_Especialidade = e.ID_Especialidade
WHERE c.Status = 'Realizada';
