# Relatório Prático: Laboratório Integrador de Banco de Dados
## Da Planilha Bruta à Arquitetura Relacional (PostgreSQL) e NoSQL (MongoDB)

**Disciplina:** Tópicos Avançados de Banco de Dados  
**Professor:** Milton Santos  
**Estudante:** [Preencha seu Nome Completo]  
**Matrícula:** [Preencha sua Matrícula] | **Turma:** [Preencha sua Turma/Curso]  
**Data de Entrega:** [DD/MM/AAAA]

---

## 📄 PÁGINA 1: Diagnóstico de Violações na Planilha (`dados_hospital.csv`)

Abaixo estão identificadas as principais falhas estruturais e anomalias da planilha bruta fornecida pelo hospital:

| Regra Violada | Colunas Afetadas no CSV | Problema Técnico Identificado | Como foi resolvido no PostgreSQL (3FN) |
| :--- | :--- | :--- | :--- |
| **1ª Forma Normal (1FN)**<br/>*Atributos Multivalorados* | `Paciente_Telefones`<br/>`Paciente_Alergias`<br/>`Medicamentos_Prescritos` | Múltiplos dados guardados na mesma célula separados por vírgula, impedindo buscas atômicas e indexadas. | Criação de tabelas satélites 1:N (`Paciente_Telefone`, `Paciente_Alergia`, `Prescricao`). |
| **2ª Forma Normal (2FN)**<br/>*Dependência Parcial* | `Procedimentos_Realizados_Valores` | O nome e o valor de tabela do procedimento não dependem da consulta, mas sim do procedimento em si. | Criação da tabela domínio `Procedimento` e associativa `Consulta_Procedimento`. |
| **3ª Forma Normal (3FN)**<br/>*Dependência Transitiva* | `Medico_Nome`<br/>`Medico_Especialidade`<br/>`Convenio_Nome` | Informações de cadastro que se repetem a cada atendimento gerando redundância e anomalia de atualização. | Criação das tabelas mestres `Medico`, `Especialidade` e `Convenio`. |

---

## 📄 PÁGINA 2: Desafio 1 — Diagnóstico com `EXPLAIN ANALYZE` (PostgreSQL)

### 1. Código SQL Executado:
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    m.ID_Medico,
    m.Nome_Medico,
    COUNT(cp.ID_Procedimento) AS Total_Procedimentos
FROM Medico m
JOIN Consulta c ON c.ID_Medico = m.ID_Medico
JOIN Consulta_Procedimento cp ON cp.ID_Consulta = c.ID_Consulta
WHERE c.Data_Hora_Inicio >= '2023-10-01' 
  AND c.Data_Hora_Inicio <  '2023-11-01'
  AND c.Status = 'Realizada'
GROUP BY m.ID_Medico, m.Nome_Medico
ORDER BY Total_Procedimentos DESC
LIMIT 1;
```

### 2. Print do Resultado e do Plano de Execução no DBeaver / Terminal:
> *(Cole aqui a captura de tela legível da sua execução mostrando as linhas retornadas e a árvore do EXPLAIN ANALYZE)*
> 
> `[COLE SEU PRINT AQUI]`

### 3. Parecer Técnico sobre o Plano de Execução (1 Parágrafo):
> **Análise do Aluno:** *(Exemplo: O médico que mais realizou procedimentos no período foi o Dr. Carlos Almeida com X procedimentos. Ao analisar o nó de junção gerado pelo otimizador do PostgreSQL, observou-se a escolha do algoritmo [Nested Loop / Hash Join]. Essa escolha se justifica porque [explique: para a massa de dados atual o custo de escanear o índice é menor que construir a tabela hash em memória, etc.]).*

---

## 📄 PÁGINA 3: Desafios 2 e 3 — MongoDB & Decisão de Arquitetura

### 1. Desafio 2: Pipeline Analítico no MongoDB (`$unwind` + `$group`)
```javascript
db.atendimentos.aggregate([
  { $match: { "paciente.alergias": "Penicilina" } },
  { $unwind: "$prescricoes" },
  { $group: { _id: "$prescricoes.medicamento", total: { $sum: 1 } } },
  { $sort: { total: -1 } },
  { $limit: 1 }
]);
```

### 2. Print da Consulta e Resultado no DBeaver / `mongosh`:
> *(Cole aqui a captura de tela legível mostrando o pipeline executado e o medicamento retornado)*
> 
> `[COLE SEU PRINT AQUI]`

---

### 3. Desafio 3: Parecer de Arquitetura para Exames Médicos de 50MB (1 Parágrafo Obrigatório)

> **Decisão de Engenharia:**  
> Armazenar as imagens de Ressonância Magnética diretamente dentro do documento BSON do MongoDB é tecnicamente inviável, pois o motor do MongoDB impõe um **limite físico estrito de 16MB por documento**. Embora o *GridFS* permita fatiar arquivos grandes dentro do banco, essa abordagem polui a memória RAM do cache do WiredTiger com dados binários pesados. Portanto, a arquitetura moderna recomendada é utilizar um **Object Storage dedicado (como AWS S3 ou MinIO local)** para persistir o arquivo bruto de 50MB via streaming, gravando no documento do MongoDB apenas os **metadados clínicos, checksum SHA-256 e a URI/URL pré-assinada de acesso ao exame**.
