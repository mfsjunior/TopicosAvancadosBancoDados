-- Script de Criação das Tabelas para o Sistema de Gestão Hospitalar Complexo
-- Baseado no diagrama e descrição de solucao_fase1_complexa.md
-- Compatível com PostgreSQL

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
