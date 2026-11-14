# Laboratório 15: Aggregation Pipeline

## Objetivo
Escrever consultas analíticas avançadas no MongoDB (semelhante ao GROUP BY e Window Functions) usando o poderoso conceito de Pipelines em Estágios.

## Conceitos
- Aggregation Pipeline (`db.collection.aggregate`)
- Estágios (`$match`, `$group`, `$project`, `$sort`)
- Unwind (`$unwind`)
- Operadores Acumuladores (`$sum`, `$avg`)

## Problema
O RH quer um relatório analítico diretamente do MongoDB de currículos. A diretoria quer saber: "Quantos anos TOTAIS de experiência (soma de todas as empresas trabalhadas) possuem os candidatos da nossa base de currículos que sabem Docker?"

## Procedimento (Nível 1 - Execução)

O framework de agregação do Mongo funciona como uma esteira industrial. Os documentos entram no estágio 1, são filtrados, o resultado vai pro estágio 2, etc.

No terminal Mongosh, garanta que você tem o documento de teste do laboratório 12:
```javascript
use adv_curriculos
```

Construa a Pipeline Estágio a Estágio:
```javascript
db.curriculos.aggregate([
    // Estágio 1: Filtrar quem tem 'Docker'
    { $match: { skills: "Docker" } },
    
    // Estágio 2: "Desdobrar" o array de experiências em linhas separadas
    { $unwind: "$experiencias" },
    
    // Estágio 3: Agrupar pelo ID do candidato somando os anos
    { $group: { 
        _id: "$nome", 
        anosTotais: { $sum: "$experiencias.anos" } 
    }}
])
```

## Investigação (Nível 2)
Observe o estágio `$unwind`. Ele é o equivalente conceitual de qual operação em Bancos Relacionais? 
Se o candidato "João" tinha 2 objetos no array `experiencias`, o que o estágio `$unwind` fez com o documento dele antes de repassar os dados para o `$group`?

## Desafio (Nível 3)
Crie um Pipeline usando o MongoDB Shell que replique o comportamento de um JOIN relacional.
Nós temos a Collection de `vagas` e a Collection de `empresas`.
Utilize o estágio `$lookup` (Pesquise a sintaxe) para trazer os dados da Empresa de dentro de outra collection e aninhá-los num campo dentro da resposta da Vaga. 

Escreva a pipeline no arquivo `solucao.js`.

---
## Perguntas
- Por que a documentação oficial diz que o estágio `$match` DEVE ser o mais próximo possível do topo do array da Pipeline de Agregação? O que isso tem a ver com Índices?
- Em volumes gigantes, por que pipelines pesadas de agregação são lentas e como as Views Materializadas (usando o estágio `$out` ou `$merge`) resolvem esse gargalo?
