// ============================================================================
// SCRIPT NOSQL AVANÇADO (MONGODB 6+)
// Laboratório End-to-End: Modelagem em Documentos, Embedding e Aggregation
// Origem dos Dados: dados_hospital.csv
// ============================================================================

// ============================================================================
// 1. SELEÇÃO DA BASE DE DADOS (CRIAÇÃO IMPLÍCITA / LAZY ALLOCATION)
// ============================================================================
// ⚠️ DÚVIDA CLÁSSICA: "Cadê o comando CREATE DATABASE?"
// No MongoDB, NÃO EXISTE "CREATE DATABASE"!
// O comando use("hospital_db") apenas alterna o ponteiro de contexto da sessão.
// A base de dados só é criada FISICAMENTE no disco no momento em que a primeira
// coleção ou documento for persistido (Alocação Preguiçosa / Lazy Creation).
// Se você executar 'show dbs' antes de inserir um dado, o hospital_db nem aparecerá!
use("hospital_db");

// ============================================================================
// 2. LIMPEZA PREVENTIVA DAS COLLECTIONS
// ============================================================================
db.atendimentos.drop();
db.pacientes_cadastro.drop();
db.medicos_cadastro.drop();

// ============================================================================
// 3. CRIAÇÃO EXPLÍCITA DE COLLECTIONS COM VALIDAÇÃO (JSON SCHEMA)
// ============================================================================
// No MongoDB, você pode simplesmente rodar db.atendimentos.insertMany() e a 
// coleção será criada implicitamente. Porém, em ambientes corporativos e para
// governança de dados, podemos criá-la explicitamente com db.createCollection()
// aplicando regras formais de validação (JSON Schema Validator):

db.createCollection("atendimentos", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["atendimento_id", "data_hora", "status", "paciente", "medico"],
      properties: {
        atendimento_id: {
          bsonType: "int",
          description: "Identificador numérico inteiro obrigatório"
        },
        data_hora: {
          bsonType: "date",
          description: "Data e hora do atendimento (ISODate) obrigatória"
        },
        status: {
          enum: ["Agendada", "Realizada", "Cancelada", "Paciente Faltou"],
          description: "Status restrito a valores permitidos"
        },
        paciente: {
          bsonType: "object",
          required: ["cpf", "nome"],
          description: "Subdocumento do paciente com CPF e Nome obrigatórios"
        },
        medico: {
          bsonType: "object",
          required: ["crm", "nome"],
          description: "Subdocumento do médico com CRM e Nome obrigatórios"
        },
        valor_total_faturado: {
          bsonType: ["double", "decimal", "int"],
          description: "Valor financeiro consolidado"
        }
      }
    }
  }
});

// ============================================================================
// 4. CARGA DA COLEÇÃO PRINCIPAL: ATENDIMENTOS (MODELO INCORPORADO / EMBEDDED)
// ============================================================================
// No MongoDB, a Consulta/Atendimento é um fato histórico.
// Procedimentos, prescrições e dados cadastrais no momento da consulta
// são incorporados para garantir leitura atômica sem JOINs lentos.

db.atendimentos.insertMany([
  {
    atendimento_id: 1001,
    data_hora: ISODate("2023-10-15T08:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "111.111.111-11",
      nome: "João Silva",
      endereco: "Rua das Flores 123, São Paulo, SP, 01000-000",
      telefones: ["(11) 9999-1111", "(11) 3333-2222"],
      alergias: ["Amendoim", "Penicilina"]
    },
    convenio: {
      nome: "Unimed",
      cnpj: "12.345.678/0001-90",
      carteirinha: "UNI-98765"
    },
    medico: {
      crm: "12345/SP",
      nome: "Dr. Carlos Almeida",
      especialidade_atendimento: "Cardiologia",
      todas_especialidades: ["Cardiologia", "Clínico Geral", "Geriatria"]
    },
    sala: {
      numero: 101,
      andar: "1º Andar",
      equipamentos: ["Máquina de ECG", "Desfibrilador"]
    },
    procedimentos: [
      { codigo_tuss: "1010", nome: "Eletrocardiograma", valor: 150.00 },
      { codigo_tuss: "2020", nome: "Aferição de Pressão", valor: 0.00 }
    ],
    prescricoes: [
      { medicamento: "Aspirina 100mg", posologia: "2x ao dia" },
      { medicamento: "Losartana 50mg", posologia: "1x ao dia" }
    ],
    valor_total_faturado: 150.00
  },
  {
    atendimento_id: 1002,
    data_hora: ISODate("2023-10-15T09:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "222.222.222-22",
      nome: "Maria Souza",
      endereco: "Av. Paulista 900, São Paulo, SP, 01310-100",
      telefones: ["(22) 8888-4444"],
      alergias: []
    },
    convenio: {
      nome: "Bradesco Saúde",
      cnpj: "98.765.432/0001-10",
      carteirinha: "BRAD-123"
    },
    medico: {
      crm: "12345/SP",
      nome: "Dr. Carlos Almeida",
      especialidade_atendimento: "Clínico Geral",
      todas_especialidades: ["Cardiologia", "Clínico Geral", "Geriatria"]
    },
    sala: {
      numero: 102,
      andar: "1º Andar",
      equipamentos: ["Estetoscópio", "Balança"]
    },
    procedimentos: [
      { codigo_tuss: "3030", nome: "Exame Clínico", valor: 200.00 }
    ],
    prescricoes: [],
    valor_total_faturado: 200.00
  },
  {
    atendimento_id: 1003,
    data_hora: ISODate("2023-10-15T10:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "111.111.111-11",
      nome: "João Silva",
      endereco: "Rua das Flores 123, São Paulo, SP, 01000-000",
      telefones: ["(11) 9999-1111", "(11) 3333-2222"],
      alergias: ["Amendoim", "Penicilina"]
    },
    convenio: {
      nome: "Particular",
      cnpj: null,
      carteirinha: null
    },
    medico: {
      crm: "54321/RJ",
      nome: "Dra. Ana Costa",
      especialidade_atendimento: "Ortopedia",
      todas_especialidades: ["Ortopedia", "Traumatologia"]
    },
    sala: {
      numero: 205,
      andar: "2º Andar",
      equipamentos: ["Aparelho de Raio-X"]
    },
    procedimentos: [
      { codigo_tuss: "4040", nome: "Raio-X de Joelho", valor: 300.00 },
      { codigo_tuss: "5050", nome: "Curativo", valor: 50.00 }
    ],
    prescricoes: [
      { medicamento: "Ibuprofeno 400mg", posologia: "3x ao dia se dor" }
    ],
    valor_total_faturado: 350.00
  },
  {
    atendimento_id: 1004,
    data_hora: ISODate("2023-10-16T14:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "333.333.333-33",
      nome: "Pedro Gomes",
      endereco: "Rua XV de Novembro 45, Curitiba, PR, 80020-310",
      telefones: ["(33) 7777-5555"],
      alergias: ["Frutos do Mar"]
    },
    convenio: {
      nome: "Unimed",
      cnpj: "12.345.678/0001-90",
      carteirinha: "UNI-11223"
    },
    medico: {
      crm: "98765/MG",
      nome: "Dr. Marcos Paulo",
      especialidade_atendimento: "Pediatria",
      todas_especialidades: ["Pediatria"]
    },
    sala: {
      numero: 101,
      andar: "1º Andar",
      equipamentos: ["Máquina de ECG", "Desfibrilador"]
    },
    procedimentos: [
      { codigo_tuss: "3030", nome: "Exame Clínico", valor: 150.00 }
    ],
    prescricoes: [
      { medicamento: "Dipirona Gotas", posologia: "35 gotas de 6 em 6 horas" }
    ],
    valor_total_faturado: 150.00
  },
  {
    atendimento_id: 1005,
    data_hora: ISODate("2023-10-16T15:00:00Z"),
    status: "Cancelada",
    paciente: {
      cpf: "222.222.222-22",
      nome: "Maria Souza",
      endereco: "Av. Paulista 900, São Paulo, SP, 01310-100",
      telefones: ["(22) 8888-4444"],
      alergias: []
    },
    convenio: {
      nome: "SulAmérica",
      cnpj: "45.678.901/0001-50",
      carteirinha: "SUL-9988"
    },
    medico: {
      crm: "54321/RJ",
      nome: "Dra. Ana Costa",
      especialidade_atendimento: "Ortopedia",
      todas_especialidades: ["Ortopedia", "Traumatologia"]
    },
    sala: {
      numero: 205,
      andar: "2º Andar",
      equipamentos: ["Aparelho de Raio-X"]
    },
    procedimentos: [],
    prescricoes: [],
    valor_total_faturado: 0.00
  },
  {
    atendimento_id: 1006,
    data_hora: ISODate("2023-10-17T08:30:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "444.444.444-44",
      nome: "Ana Oliveira",
      endereco: "Praça Sete 10, Belo Horizonte, MG, 30130-010",
      telefones: ["(44) 6666-1111", "(44) 2222-3333"],
      alergias: ["Poeira"]
    },
    convenio: {
      nome: "Bradesco Saúde",
      cnpj: "98.765.432/0001-10",
      carteirinha: "BRAD-999"
    },
    medico: {
      crm: "12345/SP",
      nome: "Dr. Carlos Almeida",
      especialidade_atendimento: "Cardiologia",
      todas_especialidades: ["Cardiologia", "Clínico Geral", "Geriatria"]
    },
    sala: {
      numero: 101,
      andar: "1º Andar",
      equipamentos: ["Máquina de ECG", "Desfibrilador"]
    },
    procedimentos: [
      { codigo_tuss: "1010", nome: "Eletrocardiograma", valor: 150.00 }
    ],
    prescricoes: [],
    valor_total_faturado: 150.00
  },
  {
    atendimento_id: 1007,
    data_hora: ISODate("2023-10-17T11:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "555.555.555-55",
      nome: "Lucas Martins",
      endereco: "Rua Augusta 1500, São Paulo, SP, 01305-100",
      telefones: ["(11) 5555-9999"],
      alergias: ["Iodo", "Dipirona"]
    },
    convenio: {
      nome: "Particular",
      cnpj: null,
      carteirinha: null
    },
    medico: {
      crm: "98765/MG",
      nome: "Dr. Marcos Paulo",
      especialidade_atendimento: "Pediatria",
      todas_especialidades: ["Pediatria"]
    },
    sala: {
      numero: 301,
      andar: "3º Andar",
      equipamentos: ["Maca Infantil", "Balança Pediátrica"]
    },
    procedimentos: [
      { codigo_tuss: "3030", nome: "Exame Clínico", valor: 250.00 },
      { codigo_tuss: "6060", nome: "Teste do Pezinho", valor: 100.00 }
    ],
    prescricoes: [
      { medicamento: "Vitamina D", posologia: "2 gotas ao dia pela manhã" }
    ],
    valor_total_faturado: 350.00
  },
  {
    atendimento_id: 1008,
    data_hora: ISODate("2023-10-18T09:30:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "111.111.111-11",
      nome: "João Silva",
      endereco: "Rua das Flores 123, São Paulo, SP, 01000-000",
      telefones: ["(11) 9999-1111", "(11) 3333-2222"],
      alergias: ["Amendoim", "Penicilina"]
    },
    convenio: {
      nome: "SulAmérica",
      cnpj: "45.678.901/0001-50",
      carteirinha: "SUL-1234"
    },
    medico: {
      crm: "54321/RJ",
      nome: "Dra. Ana Costa",
      especialidade_atendimento: "Traumatologia",
      todas_especialidades: ["Ortopedia", "Traumatologia"]
    },
    sala: {
      numero: 205,
      andar: "2º Andar",
      equipamentos: ["Aparelho de Raio-X"]
    },
    procedimentos: [
      { codigo_tuss: "7070", nome: "Retirada de Gesso", valor: 80.00 }
    ],
    prescricoes: [
      { medicamento: "Metformina 500mg", posologia: "500mg 2x ao dia" }
    ],
    valor_total_faturado: 80.00
  },
  {
    atendimento_id: 1009,
    data_hora: ISODate("2023-10-18T14:15:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "333.333.333-33",
      nome: "Pedro Gomes",
      endereco: "Rua XV de Novembro 45, Curitiba, PR, 80020-310",
      telefones: ["(33) 7777-5555"],
      alergias: ["Frutos do Mar"]
    },
    convenio: {
      nome: "Unimed",
      cnpj: "12.345.678/0001-90",
      carteirinha: "UNI-11223"
    },
    medico: {
      crm: "12345/SP",
      nome: "Dr. Carlos Almeida",
      especialidade_atendimento: "Clínico Geral",
      todas_especialidades: ["Cardiologia", "Clínico Geral", "Geriatria"]
    },
    sala: {
      numero: 102,
      andar: "1º Andar",
      equipamentos: ["Estetoscópio", "Balança"]
    },
    procedimentos: [
      { codigo_tuss: "3030", nome: "Exame Clínico", valor: 150.00 },
      { codigo_tuss: "8080", nome: "Teste Glicemia", valor: 20.00 }
    ],
    prescricoes: [],
    valor_total_faturado: 170.00
  },
  {
    atendimento_id: 1010,
    data_hora: ISODate("2023-10-19T10:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "666.666.666-66",
      nome: "Carla Dias",
      endereco: "Av. Brasil 100, Rio de Janeiro, RJ, 20040-000",
      telefones: ["(21) 1234-5678", "(21) 9876-5432"],
      alergias: []
    },
    convenio: {
      nome: "Amil",
      cnpj: "11.222.333/0001-44",
      carteirinha: "AMIL-5566"
    },
    medico: {
      crm: "54321/RJ",
      nome: "Dra. Ana Costa",
      especialidade_atendimento: "Ortopedia",
      todas_especialidades: ["Ortopedia", "Traumatologia"]
    },
    sala: {
      numero: 205,
      andar: "2º Andar",
      equipamentos: ["Aparelho de Raio-X"]
    },
    procedimentos: [
      { codigo_tuss: "3030", nome: "Consulta Simples", valor: 100.00 }
    ],
    prescricoes: [
      { medicamento: "Paracetamol 750mg", posologia: "750mg se dor" }
    ],
    valor_total_faturado: 100.00
  },
  {
    atendimento_id: 1011,
    data_hora: ISODate("2023-10-19T16:00:00Z"),
    status: "Paciente Faltou",
    paciente: {
      cpf: "444.444.444-44",
      nome: "Ana Oliveira",
      endereco: "Praça Sete 10, Belo Horizonte, MG, 30130-010",
      telefones: ["(44) 6666-1111", "(44) 2222-3333"],
      alergias: ["Poeira"]
    },
    convenio: {
      nome: "Amil",
      cnpj: "11.222.333/0001-44",
      carteirinha: "AMIL-1122"
    },
    medico: {
      crm: "98765/MG",
      nome: "Dr. Marcos Paulo",
      especialidade_atendimento: "Pediatria",
      todas_especialidades: ["Pediatria"]
    },
    sala: {
      numero: 301,
      andar: "3º Andar",
      equipamentos: ["Maca Infantil", "Balança Pediátrica"]
    },
    procedimentos: [],
    prescricoes: [],
    valor_total_faturado: 0.00
  },
  {
    atendimento_id: 1012,
    data_hora: ISODate("2023-10-20T08:00:00Z"),
    status: "Realizada",
    paciente: {
      cpf: "555.555.555-55",
      nome: "Lucas Martins",
      endereco: "Rua Augusta 1500, São Paulo, SP, 01305-100",
      telefones: ["(11) 5555-9999"],
      alergias: ["Iodo", "Dipirona"]
    },
    convenio: {
      nome: "Bradesco Saúde",
      cnpj: "98.765.432/0001-10",
      carteirinha: "BRAD-777"
    },
    medico: {
      crm: "12345/SP",
      nome: "Dr. Carlos Almeida",
      especialidade_atendimento: "Cardiologia",
      todas_especialidades: ["Cardiologia", "Clínico Geral", "Geriatria"]
    },
    sala: {
      numero: 101,
      andar: "1º Andar",
      equipamentos: ["Máquina de ECG", "Desfibrilador"]
    },
    procedimentos: [
      { codigo_tuss: "1010", nome: "Eletrocardiograma", valor: 150.00 },
      { codigo_tuss: "9090", nome: "Teste Ergométrico", valor: 300.00 }
    ],
    prescricoes: [
      { medicamento: "Atenolol 25mg", posologia: "25mg 1x ao dia pela manhã" }
    ],
    valor_total_faturado: 450.00
  }
]);

// ============================================================================
// 5. ÍNDICES NO MONGODB
// ============================================================================
// 5.1. Índice Composto para consultas por médico e data
db.atendimentos.createIndex({ "medico.crm": 1, "data_hora": -1 });

// 5.2. Multikey Index em Arrays (indexa cada alergia e cada telefone)
db.atendimentos.createIndex({ "paciente.alergias": 1 });
db.atendimentos.createIndex({ "procedimentos.codigo_tuss": 1 });

// ============================================================================
// 6. CONSULTAS AVANÇADAS COM OPERADORES
// ============================================================================

// 6.1. Consulta com $elemMatch (busca procedimentos que custaram >= 200)
print("\n--- ATENDIMENTOS COM PROCEDIMENTOS >= R$ 200.00 ---");
printjson(
  db.atendimentos.find(
    {
      procedimentos: {
        $elemMatch: { valor: { $gte: 200.00 } }
      }
    },
    { atendimento_id: 1, "paciente.nome": 1, procedimentos: 1, _id: 0 }
  ).toArray()
);

// 6.2. Consulta em Array Simples: Pacientes alérgicos a Penicilina
print("\n--- ATENDIMENTOS DE PACIENTES ALÉRGICOS A PENICILINA ---");
printjson(
  db.atendimentos.find(
    { "paciente.alergias": "Penicilina" },
    { atendimento_id: 1, "paciente.nome": 1, "paciente.alergias": 1, _id: 0 }
  ).toArray()
);

// ============================================================================
// 7. PIPELINES DE AGREGAÇÃO (ESTEIRAS ANALÍTICAS)
// ============================================================================

// PIPELINE 1: Faturamento e Ticket Médio por Especialidade Médica
print("\n--- RELATÓRIO ANALÍTICO: FATURAMENTO POR ESPECIALIDADE ---");
printjson(
  db.atendimentos.aggregate([
    { $match: { status: "Realizada" } },
    {
      $group: {
        _id: "$medico.especialidade_atendimento",
        total_consultas: { $sum: 1 },
        faturamento_total: { $sum: "$valor_total_faturado" },
        ticket_medio: { $avg: "$valor_total_faturado" }
      }
    },
    {
      $project: {
        _id: 0,
        especialidade: "$_id",
        total_consultas: 1,
        faturamento_total: { $round: ["$faturamento_total", 2] },
        ticket_medio: { $round: ["$ticket_medio", 2] }
      }
    },
    { $sort: { faturamento_total: -1 } }
  ]).toArray()
);

// PIPELINE 2: $unwind - Procedimentos mais Realizados e Faturamento Total por Procedimento
print("\n--- RELATÓRIO ANALÍTICO: PROCEDIMENTOS MAIS REALIZADOS ---");
printjson(
  db.atendimentos.aggregate([
    { $match: { status: "Realizada" } },
    { $unwind: "$procedimentos" },
    {
      $group: {
        _id: "$procedimentos.nome",
        codigo: { $first: "$procedimentos.codigo_tuss" },
        quantidade_feita: { $sum: 1 },
        receita_gerada: { $sum: "$procedimentos.valor" }
      }
    },
    {
      $project: {
        _id: 0,
        procedimento: "$_id",
        codigo_tuss: "$codigo",
        quantidade_feita: 1,
        receita_gerada: { $round: ["$receita_gerada", 2] }
      }
    },
    { $sort: { quantidade_feita: -1, receita_gerada: -1 } }
  ]).toArray()
);
