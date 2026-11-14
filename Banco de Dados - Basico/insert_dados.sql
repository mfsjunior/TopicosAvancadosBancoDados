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
-- Carlos Souza (ID 3) é paciente particular, sem convênio

INSERT INTO Medico_Especialidade (ID_Medico, ID_Especialidade) VALUES
(1, 1), -- Dr. Roberto Costa: Cardiologia
(2, 2), -- Dra. Ana Paula: Ortopedia
(3, 3), -- Dr. Marcos Lima: Pediatria
(1, 4); -- Dr. Roberto Costa também tem especialidade em Dermatologia

INSERT INTO Equipamento (ID_Equipamento, ID_Sala, Numero_Serie, Nome_Equipamento, Data_Manutencao) VALUES
(1, 1, 'EQP-001', 'Máquina de ECG', '2026-08-15'),
(2, 2, 'EQP-002', 'Aparelho de Raio-X', '2026-07-10'),
(3, 3, 'EQP-003', 'Balança Pediátrica', '2026-09-01');

-- 4. O Evento Central: A Consulta

INSERT INTO Consulta (ID_Consulta, ID_Paciente, ID_Medico, ID_Especialidade, ID_Sala, ID_Paciente_Convenio, Data_Hora_Inicio, Duracao_Minutos, Status) VALUES
-- Consulta 1: João (Convênio Unimed) com Dr. Roberto (Cardiologia)
(1, 1, 1, 1, 1, 1, '2026-09-25 09:00:00', 30, 'Agendada'),
-- Consulta 2: Maria (Convênio Bradesco) com Dra. Ana Paula (Ortopedia)
(2, 2, 2, 2, 2, 2, '2026-09-25 10:30:00', 45, 'Realizada'),
-- Consulta 3: Carlos (Particular) com Dr. Marcos (Pediatria)
(3, 3, 3, 3, 3, NULL, '2026-09-26 14:00:00', 20, 'Agendada');

-- 5. Pós-Consulta (Receitas e Atos Médicos)

INSERT INTO Consulta_Procedimento (ID_Consulta, ID_Procedimento) VALUES
(1, 1), -- Consulta 1 cobrou o procedimento "Consulta em consultório"
(1, 2), -- Consulta 1 também teve um "Eletrocardiograma"
(2, 1), -- Consulta 2 cobrou "Consulta em consultório"
(2, 3); -- Consulta 2 teve "Raio-X de Tórax"

INSERT INTO Prescricao (ID_Consulta, ID_Medicamento, Dosagem, Instrucoes_Uso) VALUES
(1, 4, '1 comprimido', 'Tomar pela manhã todos os dias'),
(2, 2, '40 gotas', 'Tomar de 8 em 8 horas em caso de dor');
