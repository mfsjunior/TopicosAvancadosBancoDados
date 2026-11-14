# Laboratório 12: Introdução ao MongoDB e Documentos

## Objetivo
Entender o modelo Não-Relacional (Document-Oriented), a estrutura JSON/BSON, e introduzir as operações básicas do MongoDB.

## Conceitos
- Database e Collection (vs Schema e Table)
- Document e BSON (vs Tupla/Linha)
- Inserção de dados (`insertOne`, `insertMany`)
- Busca de dados (`find`, `findOne`)

## Problema
Embora o PostgreSQL com JSONB tenha resolvido o currículo flexível, a diretoria percebeu que o sistema principal relacional (Vagas, Candidaturas) está concorrendo por I/O e CPU com os Pesquisadores de Currículos, que ficam o dia inteiro varrendo descrições textuais gigantescas. Eles decidiram mover todo o serviço de "Catálogo de Currículos" para uma arquitetura orientada a documentos no MongoDB.

## Procedimento (Nível 1 - Execução)

Vamos nos conectar ao container do MongoDB que já está rodando desde a Aula 01!

1. No terminal do seu computador, execute:
```bash
docker exec -it adv_db_mongodb mongosh -u root -p root_password
```

2. Crie e mude para o banco de dados de currículos:
```javascript
use adv_curriculos
```

3. Insira o primeiro currículo na Collection (ela é criada automaticamente!):
```javascript
db.curriculos.insertOne({
    candidato_id: 1,
    nome: "João Silva",
    experiencias: [
        { empresa: "TechCorp", cargo: "DevOps", anos: 3 },
        { empresa: "WebStart", cargo: "Backend", anos: 2 }
    ],
    skills: ["Docker", "Linux", "Node.js"]
})
```

4. Busque o documento que acabamos de criar:
```javascript
db.curriculos.find({ "nome": "João Silva" })
```

## Investigação (Nível 2)
Faça a seguinte busca no seu terminal mongosh:
```javascript
db.curriculos.find({ "skills": "Docker" })
```
O documento do João retornou! 
Compare isso com o PostgreSQL: Se `skills` fosse um `ARRAY` nativo no PostgreSQL, nós conseguiríamos usar `WHERE skills = 'Docker'`? Não. (Teríamos que usar `WHERE 'Docker' = ANY(skills)`). 
Por que o MongoDB retorna o documento inteiro mesmo quando fazemos uma busca de igualdade (`=`) num Array embutido?

## Desafio (Nível 3)
Pesquise a documentação do MongoDB e escreva o comando para atualizar (UPDATE) o documento do João Silva. O seu comando deve adicionar a skill `"PostgreSQL"` na lista de skills **sem** reescrever o array inteiro (utilize o operador de array `$push`).

---
## Perguntas
- O que é o `_id` gerado automaticamente pelo MongoDB? Por que ele contém o carimbo de tempo (timestamp) de criação internamente?
- Uma das grandes diferenças entre Relacional e Documento é o Schema "Flexível". Quais são os perigos de longo prazo de deixar qualquer desenvolvedor inserir qualquer chave (ex: `telefone` em vez de `celular`) na mesma collection?
