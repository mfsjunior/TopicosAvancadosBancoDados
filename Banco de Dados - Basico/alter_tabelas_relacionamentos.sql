-- Script de Criação de Relacionamentos (Chaves Estrangeiras)
-- Compatível com PostgreSQL

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
