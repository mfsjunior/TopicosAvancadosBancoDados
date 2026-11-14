-- 001-schema.sql
-- Criação do Schema Base da Plataforma de Recrutamento

CREATE TABLE empresa (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    cnpj VARCHAR(20) UNIQUE NOT NULL,
    setor VARCHAR(100),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE recrutador (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE candidato (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    data_nascimento DATE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE vaga (
    id SERIAL PRIMARY KEY,
    empresa_id INT NOT NULL REFERENCES empresa(id) ON DELETE CASCADE,
    recrutador_id INT NOT NULL REFERENCES recrutador(id) ON DELETE CASCADE,
    titulo VARCHAR(255) NOT NULL,
    descricao TEXT,
    salario NUMERIC(10, 2),
    status VARCHAR(50) DEFAULT 'ABERTA', -- ABERTA, PAUSADA, ENCERRADA
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE habilidade (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE candidato_habilidade (
    candidato_id INT NOT NULL REFERENCES candidato(id) ON DELETE CASCADE,
    habilidade_id INT NOT NULL REFERENCES habilidade(id) ON DELETE CASCADE,
    nivel_experiencia INT CHECK (nivel_experiencia BETWEEN 1 AND 5),
    PRIMARY KEY (candidato_id, habilidade_id)
);

CREATE TABLE candidatura (
    id SERIAL PRIMARY KEY,
    candidato_id INT NOT NULL REFERENCES candidato(id) ON DELETE CASCADE,
    vaga_id INT NOT NULL REFERENCES vaga(id) ON DELETE CASCADE,
    status VARCHAR(50) DEFAULT 'APLICADA', -- APLICADA, EM_ANALISE, ENTREVISTA, OFERTA, REJEITADA
    data_aplicacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (candidato_id, vaga_id)
);

CREATE TABLE entrevista (
    id SERIAL PRIMARY KEY,
    candidatura_id INT NOT NULL REFERENCES candidatura(id) ON DELETE CASCADE,
    recrutador_id INT NOT NULL REFERENCES recrutador(id) ON DELETE CASCADE,
    data_hora TIMESTAMP NOT NULL,
    feedback TEXT,
    nota INT CHECK (nota BETWEEN 1 AND 10),
    realizada BOOLEAN DEFAULT FALSE
);

CREATE TABLE avaliacao (
    id SERIAL PRIMARY KEY,
    candidatura_id INT NOT NULL REFERENCES candidatura(id) ON DELETE CASCADE,
    pontuacao NUMERIC(5, 2) NOT NULL,
    data_avaliacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
