-- Script de Relacionamentos (Chaves Estrangeiras)
-- Sistema de Gestão Hospitalar Complexo

-- 1. Paciente_Telefone
ALTER TABLE Paciente_Telefone
ADD CONSTRAINT FK_Paciente_Telefone_Paciente
FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE;

-- 2. Paciente_Alergia
ALTER TABLE Paciente_Alergia
ADD CONSTRAINT FK_Paciente_Alergia_Paciente
FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE;

-- 3. Paciente_Convenio
ALTER TABLE Paciente_Convenio
ADD CONSTRAINT FK_Paciente_Convenio_Paciente
FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente) ON DELETE CASCADE;

ALTER TABLE Paciente_Convenio
ADD CONSTRAINT FK_Paciente_Convenio_Convenio
FOREIGN KEY (ID_Convenio) REFERENCES Convenio(ID_Convenio) ON DELETE CASCADE;

-- 4. Medico_Especialidade
ALTER TABLE Medico_Especialidade
ADD CONSTRAINT FK_Medico_Especialidade_Medico
FOREIGN KEY (ID_Medico) REFERENCES Medico(ID_Medico) ON DELETE CASCADE;

ALTER TABLE Medico_Especialidade
ADD CONSTRAINT FK_Medico_Especialidade_Especialidade
FOREIGN KEY (ID_Especialidade) REFERENCES Especialidade(ID_Especialidade) ON DELETE CASCADE;

-- 5. Equipamento
ALTER TABLE Equipamento
ADD CONSTRAINT FK_Equipamento_Sala
FOREIGN KEY (ID_Sala) REFERENCES Sala(ID_Sala) ON DELETE SET NULL;

-- 6. Consulta
ALTER TABLE Consulta
ADD CONSTRAINT FK_Consulta_Paciente
FOREIGN KEY (ID_Paciente) REFERENCES Paciente(ID_Paciente);

ALTER TABLE Consulta
ADD CONSTRAINT FK_Consulta_Medico
FOREIGN KEY (ID_Medico) REFERENCES Medico(ID_Medico);

ALTER TABLE Consulta
ADD CONSTRAINT FK_Consulta_Especialidade
FOREIGN KEY (ID_Especialidade) REFERENCES Especialidade(ID_Especialidade);

ALTER TABLE Consulta
ADD CONSTRAINT FK_Consulta_Sala
FOREIGN KEY (ID_Sala) REFERENCES Sala(ID_Sala);

ALTER TABLE Consulta
ADD CONSTRAINT FK_Consulta_Paciente_Convenio
FOREIGN KEY (ID_Paciente_Convenio) REFERENCES Paciente_Convenio(ID_Paciente_Convenio);

-- 7. Consulta_Procedimento
ALTER TABLE Consulta_Procedimento
ADD CONSTRAINT FK_Consulta_Procedimento_Consulta
FOREIGN KEY (ID_Consulta) REFERENCES Consulta(ID_Consulta) ON DELETE CASCADE;

ALTER TABLE Consulta_Procedimento
ADD CONSTRAINT FK_Consulta_Procedimento_Procedimento
FOREIGN KEY (ID_Procedimento) REFERENCES Procedimento(ID_Procedimento);

-- 8. Prescricao
ALTER TABLE Prescricao
ADD CONSTRAINT FK_Prescricao_Consulta
FOREIGN KEY (ID_Consulta) REFERENCES Consulta(ID_Consulta) ON DELETE CASCADE;

ALTER TABLE Prescricao
ADD CONSTRAINT FK_Prescricao_Medicamento
FOREIGN KEY (ID_Medicamento) REFERENCES Medicamento(ID_Medicamento);
