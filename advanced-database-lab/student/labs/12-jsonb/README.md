# Laboratório 11: JSON e Dados Semiestruturados no SGBD Relacional

## Objetivo
Entender as vantagens e limitações de armazenar documentos semiestruturados (JSON) nativamente dentro do PostgreSQL, unindo o melhor dos mundos Relacional e Não-Relacional (Documentos).

## Problema
O RH começou a exigir que o sistema anexe os currículos dos candidatos e notas extras variáveis. Porém, o formato dos currículos muda todo mês (um mês pedem Github, noutro pedem LinkedIn, noutro pedem um portfólio customizado). Se continuarmos adicionando colunas (ALTER TABLE) na tabela `candidato`, teremos dezenas de colunas em branco ou desorganizadas.

## Procedimento (Nível 1 - Execução)

A solução da equipe foi criar uma coluna flexível utilizando o poderoso tipo `JSONB` do PostgreSQL.

1. Altere a estrutura do banco:
```sql
ALTER TABLE candidato ADD COLUMN metadados JSONB;
```

2. Insira dados heterogêneos para dois candidatos:
```sql
UPDATE candidato 
SET metadados = '{"links": {"github": "github.com/candidato1", "portfolio": "meusite.com"}, "idiomas": ["Inglês", "Espanhol"]}' 
WHERE id = 1;

UPDATE candidato 
SET metadados = '{"links": {"linkedin": "linkedin.com/in/candidato2"}, "certificacoes": ["AWS", "Scrum"]}' 
WHERE id = 2;
```

3. Como buscar uma informação enterrada dentro do JSON (como o github)? Usamos o operador `->>`:
```sql
SELECT nome, metadados->'links'->>'github' AS perfil_github 
FROM candidato 
WHERE metadados->'links'->>'github' IS NOT NULL;
```

## Investigação (Nível 2)
Se começarmos a pesquisar candidatos pelos "idiomas" ou "certificações", e tivermos 1 milhão de candidatos, a busca em uma string JSON vai gerar um caríssimo *Seq Scan*, derrubando a performance.
Pesquise e descreva a diferença física de armazenamento entre o tipo `JSON` puro e o `JSONB` (com B) no PostgreSQL. Por que você jamais deveria usar apenas `JSON` se for pesquisar pelos dados internos?

## Desafio (Nível 3)
Pesquisas em `JSONB` exigem índices específicos de texto invertido.
Crie a sintaxe SQL de um Índice GIN (Generalized Inverted Index) para indexar o campo `metadados` da tabela candidato, permitindo que a busca abaixo seja ultrarrápida:

```sql
SELECT nome FROM candidato WHERE metadados @> '{"idiomas": ["Inglês"]}';
```
Faça o EXPLAIN para provar que a busca foi indexada.

---
## Perguntas
- Em termos de Modelagem de Banco, se você *sempre* faz pesquisas ou joins por um campo do JSON (ex: "id_do_curso"), por que deixá-lo no JSON é um Anti-Pattern comparado a extraí-lo como uma coluna real relacional?
- O que é o índice GIN e como a estrutura dele é diferente de uma B-Tree convencional para conseguir indexar sub-elementos de um documento JSON?
